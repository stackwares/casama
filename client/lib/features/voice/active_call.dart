import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics.dart';
import '../../core/backend.dart';
import '../../core/call_audio.dart';
import '../../core/providers.dart';
import '../../core/nav.dart';
import '../../core/router.dart';
import '../../core/voice.dart';
import '../chat/chat_screen.dart' show computerForBot;
import 'call_activity.dart';
import 'call_system.dart';

/// Why a call ended.
enum CallEnd {
  /// The red button, the bubble, the notification or CallKit.
  hungUp,

  /// Nobody speaking and no job running for the silence limit (a minute by default, set by the
  /// server, D-426).
  idle,

  /// It couldn't connect, or dropped and couldn't resume.
  failed,

  /// Another call took its place (D-327 §5).
  replaced,

  /// The server ended it (no heartbeat in time).
  server,

  /// It reached a limit (D-426): its longest length, or the workspace's credits or budgets.
  limit,

  /// The bot hung up after saying goodbye (`end_call`, D-423).
  bot,
}

/// A call's finished turns, saved while the call goes on (D-327 §4): each turn is posted once,
/// by its id; a failed post stays queued and is tried again a little later.
class TurnSaver {
  TurnSaver({
    required this.post,
    this.retryAfter = const Duration(seconds: 2),
    this.maxRetryAfter = const Duration(seconds: 30),
  });

  final Future<void> Function(List<(String, String, String)> turns) post;
  final Duration retryAfter;
  final Duration maxRetryAfter;

  final _pending = <(String, String, String)>[];
  var _busy = false;
  Timer? _retry;
  late Duration _wait = retryAfter;
  var _closed = false;

  /// Turns not saved yet: (id, role, text).
  List<(String, String, String)> get unsent => List.unmodifiable(_pending);

  void add(String id, String role, String text) {
    if (_closed) return;
    _pending.add((id, role, text));
    unawaited(flush());
  }

  /// Posts whatever is queued now. Returns once that try is over (saved or not).
  Future<void> flush() async {
    if (_busy || _pending.isEmpty) return;
    _busy = true;
    _retry?.cancel();
    final batch = List.of(_pending.take(100));
    try {
      await post(batch);
      _pending.removeRange(0, batch.length);
      _wait = retryAfter;
    } catch (e) {
      debugPrint('call turns not saved yet: $e');
      if (!_closed) {
        _retry = Timer(_wait, () => unawaited(flush()));
        _wait = _wait * 2 > maxRetryAfter ? maxRetryAfter : _wait * 2;
      }
    } finally {
      _busy = false;
    }
    // Turns that arrived during the post.
    if (_pending.isNotEmpty && _retry == null && !_closed) await flush();
  }

  /// Stops retrying; what's left goes with the hang-up.
  void close() {
    _closed = true;
    _retry?.cancel();
    _retry = null;
  }
}

/// Where a job started on a call stands (D-327 §6).
enum CallJobState { running, needsApproval, needsTakeover, done, failed, cancelled }

/// A job started on a call (`start_task`, or a tool still running after 12 s), followed through
/// its run events until it ends, so the bot can say how it went.
class CallJob {
  CallJob({required this.runId, required this.title, required this.card})
    : started = DateTime.now();
  final String runId;

  /// What it's doing, in the person's words (the task), or empty for a tool.
  final String title;

  /// Its card on the call screen ("Working on it" while it runs).
  final ToolRun card;
  final DateTime started;
  CallJobState state = CallJobState.running;

  /// It has used the bot's computer (or is waking it): the call shows the live-view tile.
  bool usesComputer = false;
  String? computerId;

  /// The last thing it said (its reply), for the note to the bot.
  String? reply;

  bool get active =>
      state == CallJobState.running ||
      state == CallJobState.needsApproval ||
      state == CallJobState.needsTakeover;
}

/// run_id for a call tool that started no run.
const _noRun = '00000000-0000-0000-0000-000000000000';

/// Tools that mean a job is working on the bot's computer (the chat's own test, D-162).
const _computerTools = ['shell', 'desktop', 'computer', 'checkpoint', 'browser', 'files'];

/// One live call, owned by the app rather than a screen (D-327): the session, the voice
/// connection, mute, the audio route, the tools the bot runs, the idle check, turns saved as they
/// happen and the heartbeat. The call screen, the bubble and the sidebar card are views of it.
class CallController extends ChangeNotifier {
  CallController({
    required this.backend,
    required this.connector,
    required this.botId,
    this.requestedConversationId,
    this.phoneCallId,
    this._idleLimit = const Duration(minutes: 1),
    this._heartbeatEvery = const Duration(seconds: 30),
    this.pauseBeforeNote = const Duration(milliseconds: 1500),
    this.goodbyeGrace = const Duration(milliseconds: 1200),
    this.goodbyeLimit = const Duration(seconds: 10),
    this.onEnded,
    this.onShowScreen,
    CallSystem? system,
    this.interruptions,
    this.botName = '',
    this.botAvatar,
    this.onOpen,
  }) : system = system ?? NoCallSystem();

  final Backend backend;
  final VoiceCallConnector connector;
  final String botId;
  final String? requestedConversationId;

  /// An answered phone-style ring (D-135).
  final String? phoneCallId;

  /// Silence before the call hangs up, and how often it tells the server it's open. The server's
  /// values (Admin → Call limits, D-426) replace these when the session carries them.
  Duration get idleLimit => _idleLimit;
  Duration _idleLimit;
  Duration get heartbeatEvery => _heartbeatEvery;
  Duration _heartbeatEvery;

  /// A call the relay doesn't carry ends at its longest length here (D-426): the bot is told to
  /// warn the person, then to say goodbye, and the call hangs up after it.
  Timer? _maxWarnTimer;
  Timer? _maxEndTimer;
  Timer? _goodbyeTimer;
  var _wrappingUp = false;

  /// The bot speaks up about a job only after this long with nobody speaking (decision 8).
  final Duration pauseBeforeNote;

  /// After the bot's `end_call` (D-423): how long a goodbye still on its way gets to start, and
  /// the most the call waits for it to finish playing before it hangs up anyway.
  final Duration goodbyeGrace;
  final Duration goodbyeLimit;
  final void Function(CallController call)? onEnded;

  /// Answers the `show_screen` call tool (the app shows the bot's screen); returns what to tell the
  /// bot.
  final String Function(CallController call)? onShowScreen;

  /// The phone's call controls (D-327 §7): CallKit, Android's call notification.
  final CallSystem system;

  /// Other calls, Siri and alarms taking the audio; headphones unplugged.
  final CallInterruptions? interruptions;

  /// For the phone's call controls.
  final String botName;

  /// The bot's icon as it stores it (`mascot:<name>`), for the phone's call notification.
  final String? botAvatar;

  /// The call notification was tapped: show the call screen.
  final void Function(CallController call)? onOpen;

  StreamSubscription<CallSystemAction>? _systemSub;
  final _audioSubs = <StreamSubscription<Object?>>[];
  var _systemLive = false;
  var _held = false;

  /// Something else has the phone's audio (another call): the mic sends nothing, the bot waits.
  bool get held => _held;

  VoiceCall? _call;
  VoiceCall? get call => _call;
  Object? _error;
  Object? get error => _error;
  String? _conversationId;
  String? get conversationId => _conversationId ?? requestedConversationId;
  String? _liveCallId;
  String? get liveCallId => _liveCallId;
  String? _provider;
  final startedAt = DateTime.now();

  /// When the voice connection went live (the timer counts from here).
  DateTime? connectedAt;

  var _muted = false;
  bool get muted => _muted;
  CallRoute? _route;

  /// Where the call plays now (speaker by default), when it can choose.
  CallRoute? get route => _route;
  var _ending = false;
  bool get ending => _ending;
  CallEnd? _endedBy;
  CallEnd? get endedBy => _endedBy;
  bool get over => _endedBy != null;

  /// A hang-up whose final save failed (shown by the call screen).
  Object? saveError;

  /// Tools the bot ran on this call, newest last; finished ones fold away after a moment.
  final runs = <ToolRun>[];
  final _fades = <Timer>{};
  bool get toolsBusy => runs.any((r) => !r.settled);

  /// A tool the bot is waiting on right now (not a job running on its own): the orb thinks.
  bool get toolsWaiting => runs.any((r) => !r.settled && !r.followed);

  /// Jobs started on this call, oldest first; finished ones stay for the recap.
  final jobs = <CallJob>[];

  /// A job is still going or waiting for the person: the call doesn't hang up for quiet.
  bool get jobsBusy => jobs.any((j) => j.active);

  /// The newest job still going, for the strip under the name.
  CallJob? get activeJob => jobs.where((j) => j.active).lastOrNull;

  /// The computer a job is using (from its events), newest first.
  String? get jobComputerId =>
      jobs.reversed.map((j) => j.computerId).nonNulls.firstOrNull;

  var _tileAsked = false;
  var _tileDismissed = false;
  var _tileDone = false;
  Timer? _tileDoneTimer;

  CallJob? get _screenJob =>
      jobs.where((j) => j.active && j.usesComputer).lastOrNull;

  /// The live-view tile shows: a job is working on the computer, the bot showed its screen, or a
  /// job that used it just finished (a short "Done").
  bool get tileShown =>
      !_tileDismissed && (_tileAsked || _screenJob != null || tileDone);

  /// The job on the computer just finished.
  bool get tileDone => _screenJob == null && _tileDone;

  /// A job needs the person on the computer (a takeover): the tile turns amber.
  bool get tileNeedsYou =>
      jobs.any((j) => j.state == CallJobState.needsTakeover);

  /// The bot showed its screen (`show_screen`).
  void showTile() {
    _tileAsked = true;
    _tileDismissed = false;
    _changed();
  }

  /// The tile's close button; a job that starts using the computer later brings it back.
  void hideTile() {
    _tileAsked = false;
    _tileDismissed = true;
    _tileDone = false;
    _changed();
  }

  final _jobSubs = <StreamSubscription<RunEventItem>>[];
  final _notes = <String>[];
  Timer? _noteTimer;
  DateTime? _stoppedAt;

  /// A tool waits for the person's OK (the bubble shows an amber dot).
  bool get needsPerson =>
      runs.any((r) => r.state == ToolRunState.needsApproval);

  CallState get state {
    if (_error != null) return CallState.failed;
    if (over) return CallState.ended;
    return _call?.state.value ?? CallState.connecting;
  }

  bool get live => state == CallState.live && !_ending;

  /// The connection dropped and is being resumed (the bubble and notification say so).
  bool get reconnecting => _call?.reconnecting?.value ?? false;

  /// How long the call has been live.
  Duration get elapsed => connectedAt == null
      ? Duration.zero
      : DateTime.now().difference(connectedAt!);

  late final _turns = TurnSaver(
    post: (t) => backend.saveVoiceTurns(_liveCallId!, t),
  );
  var _seenTurns = 0;
  Timer? _idleTimer;
  Timer? _heartbeat;
  Duration _idleTick = const Duration(seconds: 10);
  var _quietTicks = 0;
  StreamSubscription<CallToolRequest>? _toolSub;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void _activity() {
    _quietTicks = 0;
    if (_notes.isNotEmpty) _armNotes();
  }

  void _checkIdle() {
    final call = _call;
    if (call == null || _ending || over || call.state.value != CallState.live) {
      return;
    }
    if (call.speaking.value || toolsBusy || jobsBusy || _held) {
      _activity();
      return;
    }
    _quietTicks++;
    if (_idleTick * _quietTicks >= idleLimit) unawaited(end(CallEnd.idle));
  }

  /// New turns go to the server as they finish.
  void _onTranscript() {
    final turns = _call?.transcript.value ?? const <CallTurn>[];
    if (_liveCallId != null) {
      for (var i = _seenTurns; i < turns.length; i++) {
        _turns.add('t$i', turns[i].role, turns[i].text);
      }
    }
    _seenTurns = turns.length;
  }

  void _onState() {
    final s = _call?.state.value;
    if (s == CallState.live) {
      connectedAt ??= DateTime.now();
      _markLive();
    }
    // Dropped and couldn't resume: the call is over, and saved like any other. Ended by the
    // server at a limit (D-426): over too, for that reason.
    if ((s == CallState.failed || s == CallState.ended) && !_ending && !over) {
      unawaited(end(_call?.overBecause != null ? CallEnd.limit : CallEnd.failed));
    }
    _changed();
  }

  Future<void> connect() async {
    try {
      final session = await backend.voiceSession(
        botId,
        conversationId: requestedConversationId,
        callId: phoneCallId,
      );
      _conversationId = session.conversationId;
      _liveCallId = session.liveCallId;
      _provider = session.provider.value;
      final limits = session.limits;
      if (limits != null) {
        _idleLimit = Duration(seconds: limits.silenceSeconds);
        _heartbeatEvery = Duration(seconds: limits.heartbeatSeconds);
      }
      if (over || _ending) {
        await _finishRecord(const [], 0, null);
        return;
      }
      // The phone's call controls first: on iPhone the mic and player may start only once CallKit
      // has the audio session (Android's service starts alongside, without holding the call up).
      _systemSub = system.actions.listen(_onSystem);
      await system.start(
        CallSystemCall(
          id: session.liveCallId,
          botName: botName,
          botAvatar: botAvatar,
          phoneCallId: phoneCallId,
        ),
      );
      unawaited(interruptions?.begin());
      if (over || _ending) {
        await _finishRecord(const [], 0, null);
        return;
      }
      final call = await connector.connect(session);
      if (over || _ending) {
        await call.hangUp();
        await _finishRecord(const [], 0, null);
        return;
      }
      _call = call;
      if (call.state.value == CallState.live) {
        connectedAt = DateTime.now();
        _markLive();
      }
      call.state.addListener(_onState);
      call.speaking.addListener(_changed);
      call.reconnecting?.addListener(_changed);
      call.reconnecting?.addListener(_syncSystem);
      call.transcript.addListener(_changed);
      call.replyLatencyMs.addListener(_changed);
      final i = interruptions;
      if (i != null) {
        _audioSubs
          ..add(i.interrupted.listen(_setHeld))
          ..add(i.unplugged.listen((_) => _onUnplugged()));
      }
      // Speech either way keeps the call going; long silence ends it.
      call.transcript.addListener(_activity);
      call.speaking.addListener(_activity);
      call.transcript.addListener(_onTranscript);
      _activity();
      _idleTick = idleLimit < const Duration(seconds: 50)
          ? idleLimit ~/ 5
          : const Duration(seconds: 10);
      _idleTimer = Timer.periodic(_idleTick, (_) => _checkIdle());
      _heartbeat = Timer.periodic(heartbeatEvery, (_) => unawaited(_beat()));
      if (limits != null && limits.appEndsAtMax) {
        _armMaxLength(
          Duration(seconds: limits.maxCallSeconds),
          Duration(seconds: limits.warningSeconds),
        );
      }
      // Tool calls run as agent runs with the bot's approvals, then go back to the model.
      _toolSub = call.toolCalls.listen((t) => unawaited(_runTool(call, t)));
      Analytics.log('call_started', {
        'provider': _provider,
        'kind': 'in_app',
        'result': 'connected',
      });
      Analytics.feature('voice_call');
      _changed();
      unawaited(_loadRoute());
    } catch (e) {
      Analytics.log('call_started', {
        'provider': _provider,
        'kind': 'in_app',
        'result': 'failed',
      });
      _error = e;
      _changed();
      unawaited(_endSystem());
      // A session that started but never connected still ends its server record (and its hold).
      if (_liveCallId != null) {
        unawaited(_finishRecord(const [], 0, null).catchError((_) {}));
      }
    }
  }

  /// The call's longest length, kept by the app when the relay doesn't (D-426). Counted from when
  /// the call was asked for, as the server counts it.
  void _armMaxLength(Duration max, Duration warning) {
    final left = max - DateTime.now().difference(startedAt);
    _maxWarnTimer = Timer(left - warning < Duration.zero ? Duration.zero : left - warning, () {
      // Intentionally not translated: these go to the voice model, not the user.
      _call?.tellModel(
        '(Note from Casama, not from the user: this call reaches its ${max.inMinutes}-minute limit '
        'in about ${_roughly(warning)}. At the next natural pause, tell the user in one short '
        "sentence that the call is reaching its time limit and you'll have to hang up soon, then "
        'carry on.)',
      );
    });
    _maxEndTimer = Timer(left < Duration.zero ? Duration.zero : left, _wrapUp);
  }

  static String _roughly(Duration d) => d.inSeconds < 90
      ? 'a minute'
      : '${(d.inSeconds / 60).round()} minutes';

  /// The longest length is up: one goodbye from the bot, then hang up once it has finished.
  void _wrapUp() {
    final call = _call;
    if (call == null || _ending || over || _wrappingUp) return;
    _wrappingUp = true;
    call.tellModel(
      '(Note from Casama, not from the user: this call has reached its time limit, so it ends '
      'now. Say goodbye in one or two short sentences: say why, and that anything left carries on '
      "in the chat. Don't call tools or start anything new.)",
    );
    var spoke = false;
    void listen() {
      if (call.speaking.value) {
        spoke = true;
      } else if (spoke) {
        call.speaking.removeListener(listen);
        _goodbyeTimer?.cancel();
        _goodbyeTimer = Timer(const Duration(milliseconds: 800), () => unawaited(end(CallEnd.limit)));
      }
    }

    call.speaking.addListener(listen);
    // However the goodbye goes, the call is over within half a minute.
    _goodbyeTimer = Timer(const Duration(seconds: 30), () {
      call.speaking.removeListener(listen);
      unawaited(end(CallEnd.limit));
    });
  }

  void _markLive() {
    if (_systemLive) return;
    _systemLive = true;
    unawaited(system.connected());
  }

  void _syncSystem() => unawaited(
    system.update(muted: _muted, reconnecting: reconnecting),
  );

  void _onSystem(CallSystemAction a) {
    switch (a) {
      case CallSystemAction.mute:
        setMuted(true);
      case CallSystemAction.unmute:
        setMuted(false);
      case CallSystemAction.end:
        unawaited(end(CallEnd.hungUp));
      case CallSystemAction.open:
        onOpen?.call(this);
      case CallSystemAction.hold:
        _setHeld(true);
      case CallSystemAction.resume:
        _setHeld(false);
    }
  }

  /// Another call, FaceTime, Siri or an alarm took the audio, or gave it back (D-327 §7).
  void _setHeld(bool held) {
    final call = _call;
    if (held == _held || call == null || over || _ending) return;
    _held = held;
    call.setOnHold(held);
    // Intentionally not translated: these go to the voice model, not the user.
    if (held) {
      call.tellModel(
        "(Something else took the user's phone audio, like another call. They can't hear you now. Say nothing and wait.)",
      );
    } else {
      unawaited(_reclaimAudio());
      call.tellModel(
        '(The user is back on the call. Carry on where you left off, in a few words.)',
      );
      _activity();
      if (_notes.isNotEmpty) _armNotes();
    }
    _changed();
  }

  /// After an interruption: the audio session, then the route the call had.
  Future<void> _reclaimAudio() async {
    await interruptions?.reclaim();
    final r = _route;
    if (r != null) {
      try {
        await _call?.routes?.select(r);
      } catch (e) {
        debugPrint('call route not restored: $e');
      }
    }
  }

  /// Headphones unplugged: the speaker, as the system does, without stopping.
  void _onUnplugged() {
    if (_call?.routes == null || over || _ending) return;
    unawaited(
      selectRoute(
        const CallRoute(CallRouteKind.speaker),
      ).catchError((Object e) => debugPrint('speaker not selected: $e')),
    );
  }

  var _systemEnded = false;
  Future<void> _endSystem() async {
    if (_systemEnded) return;
    _systemEnded = true;
    unawaited(_systemSub?.cancel());
    for (final s in _audioSubs) {
      unawaited(s.cancel());
    }
    _audioSubs.clear();
    // Neither holds up the call's end (the service's channel may be slow or gone).
    unawaited(system.end());
    unawaited(interruptions?.finish());
  }

  Future<void> _beat() async {
    final id = _liveCallId;
    if (id == null || over || _ending) return;
    try {
      final ended = await backend.voiceHeartbeat(id, usage: _call?.usage);
      if (ended && !over && !_ending) unawaited(end(CallEnd.server));
    } catch (e) {
      // Offline for a moment: the next one tries again; the server waits a few beats.
      debugPrint('call heartbeat failed: $e');
    }
  }

  Future<void> _runTool(VoiceCall call, CallToolRequest t) async {
    // The bot hangs up itself (D-423): the app answers it and ends the call after the goodbye.
    if (t.name == 'end_call') {
      // Intentionally not translated: this goes to the voice model, not the user.
      call.sendToolResult(t.callId, 'Hanging up. Say nothing more.');
      await _hangUpAfterGoodbye(call);
      return;
    }
    // The app answers show_screen itself: the bot's screen, in the tile or full size.
    if (t.name == 'show_screen') {
      // Intentionally not translated: these go to the voice model, not the user.
      call.sendToolResult(
        t.callId,
        onShowScreen?.call(this) ??
            "There's no computer screen to show right now. Tell the user.",
      );
      return;
    }
    final run = ToolRun(id: t.callId, name: t.name, arguments: t.arguments);
    runs.add(run);
    _changed();
    try {
      final r = await backend.voiceTool(
        botId,
        conversationId!,
        t.callId,
        t.name,
        t.arguments,
        liveCallId: _liveCallId,
      );
      if (over) return;
      call.sendToolResult(t.callId, r.output);
      run.approvalId = r.approvalId;
      if (t.name == 'stop_task') _stoppedAt = DateTime.now();
      // A job that goes on after the answer: followed until it ends, and the bot hears how it went.
      final job = r.runId != _noRun &&
          ((t.name == 'start_task' &&
                  r.status == VoiceToolResultStatusEnum.completed) ||
              r.status == VoiceToolResultStatusEnum.running);
      if (job) {
        _follow(run, r.runId, t.name == 'start_task' ? '${t.arguments['task'] ?? ''}'.trim() : '');
        return;
      }
      _settle(run, switch (r.status) {
        VoiceToolResultStatusEnum.completed => ToolRunState.done,
        VoiceToolResultStatusEnum.failed => ToolRunState.failed,
        VoiceToolResultStatusEnum.waitingApproval => ToolRunState.needsApproval,
        _ => ToolRunState.background,
      });
    } catch (e) {
      if (over) return;
      // Intentionally not translated: this goes to the voice model, not the user.
      call.sendToolResult(t.callId, 'The tool could not run.');
      _settle(run, ToolRunState.failed);
    }
  }

  var _botHangingUp = false;

  /// Lets the bot's goodbye finish playing, then ends the call as the bot's hang-up.
  Future<void> _hangUpAfterGoodbye(VoiceCall call) async {
    if (_botHangingUp) return;
    _botHangingUp = true;
    final until = DateTime.now().add(goodbyeLimit);
    await Future<void>.delayed(goodbyeGrace);
    while (!over && !_ending && call.speaking.value && DateTime.now().isBefore(until)) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    if (!over && !_ending) await end(CallEnd.bot);
  }

  void _follow(ToolRun card, String runId, String title) {
    final job = CallJob(runId: runId, title: title, card: card);
    card
      ..followed = true
      ..jobTitle = title
      ..state = ToolRunState.running;
    jobs.add(job);
    _changed();
    var ended = false;
    _jobSubs.add(
      backend.watchRun(runId).listen(
        (e) {
          if (_onJobEvent(job, e)) ended = true;
        },
        onError: (Object e) => debugPrint('call job events failed: $e'),
        onDone: () {
          if (!ended && job.active) unawaited(_checkJob(job));
        },
      ),
    );
  }

  /// The run's events closed without its end (offline, or the run is gone): ask once.
  Future<void> _checkJob(CallJob job) async {
    try {
      final r = await backend.run(job.runId);
      switch (r.status) {
        case RunStatus.completed:
          _finishJob(job, CallJobState.done);
        case RunStatus.failed:
          _finishJob(job, CallJobState.failed);
        case RunStatus.cancelled:
          _finishJob(job, CallJobState.cancelled);
        default:
      }
    } catch (e) {
      debugPrint('call job check failed: $e');
    }
  }

  /// One event of a job's run. Returns true when the run ended.
  bool _onJobEvent(CallJob job, RunEventItem e) {
    if (over || !job.active) return false;
    final what = job.title.isEmpty ? 'the ${job.card.key} tool' : '"${_short(job.title, 120)}"';
    // Intentionally not translated: the notes go to the voice model, not the user.
    switch (e) {
      case ToolStartedItem(:final event):
        if (!job.usesComputer && _computerTools.any(event.payload.tool.startsWith)) {
          job.usesComputer = true;
          _tileDismissed = false;
        }
      case ComputerStateItem(:final event):
        job.computerId = event.payload.computerId;
        final asleep = const {
          ComputerStateEventPayloadStateEnum.sleeping,
          ComputerStateEventPayloadStateEnum.stopped,
          ComputerStateEventPayloadStateEnum.error,
        }.contains(event.payload.state);
        if (!asleep && !job.usesComputer) {
          job.usesComputer = true;
          _tileDismissed = false;
        }
      case ApprovalRequestedItem(:final event):
        job.state = CallJobState.needsApproval;
        job.card
          ..state = ToolRunState.needsApproval
          ..approvalId = event.payload.approvalId;
        toolHaptic(ToolRunState.needsApproval);
        _tell('(The task $what needs the user\'s OK in the app before it goes on. Tell them; they can allow it right on the call screen.)');
      case ApprovalResolvedItem():
        if (job.state == CallJobState.needsApproval) {
          job.state = CallJobState.running;
          job.card
            ..state = ToolRunState.running
            ..deciding = false;
        }
      case TakeoverRequestedItem(:final event):
        job.state = CallJobState.needsTakeover;
        job.computerId = event.payload.computerId;
        job.usesComputer = true;
        _tileDismissed = false;
        toolHaptic(ToolRunState.needsApproval);
        _tell('(The task $what needs the user on the computer: ${_short(event.payload.reason, 200)}. Tell them; they can tap the screen on the call to take over.)');
      case TakeoverResolvedItem():
        if (job.state == CallJobState.needsTakeover) job.state = CallJobState.running;
      case MessageCompletedItem(:final event):
        final text = event.payload.content
            .where((p) => p['type'] == 'text')
            .map((p) => '${p['text'] ?? ''}')
            .join(' ')
            .trim();
        if (text.isNotEmpty) job.reply = text;
      case ToolCompletedItem(:final event):
        if (job.title.isEmpty) job.reply = event.payload.resultPreview;
      case RunCompletedItem():
        _finishJob(job, CallJobState.done);
        return true;
      case RunFailedItem(:final event):
        _finishJob(job, CallJobState.failed, error: event.payload.message);
        return true;
      case RunCancelledItem():
        _finishJob(job, CallJobState.cancelled);
        return true;
      default:
        return false;
    }
    _changed();
    return false;
  }

  void _finishJob(CallJob job, CallJobState state, {String? error}) {
    if (!job.active || over) return;
    job.state = state;
    final what = job.title.isEmpty ? 'the ${job.card.key} tool' : '"${_short(job.title, 120)}"';
    // Intentionally not translated: the notes go to the voice model, not the user.
    switch (state) {
      case CallJobState.done:
        final reply = job.reply;
        _tell(
          reply == null || reply.isEmpty
              ? '(The task $what is done; the result is in the chat. Tell the user in a few words.)'
              : '(The task $what is done. It said: ${_short(reply, 400)} Tell the user in a few words.)',
        );
      case CallJobState.failed:
        _tell('(The task $what failed${error == null || error.isEmpty ? '' : ': ${_short(error, 200)}'}. Tell the user briefly.)');
      case CallJobState.cancelled:
        // stop_task already told the bot; someone stopping it in the chat hasn't.
        final recent = _stoppedAt != null &&
            DateTime.now().difference(_stoppedAt!) < const Duration(seconds: 30);
        if (!recent) _tell('(The task $what was stopped in the app. Tell the user briefly.)');
      default:
    }
    if (job.usesComputer) {
      _tileDone = true;
      _tileDoneTimer?.cancel();
      _tileDoneTimer = Timer(const Duration(seconds: 3), () {
        _tileDone = false;
        _changed();
      });
    }
    // The quiet clock starts again now the job is over.
    _activity();
    _settle(
      job.card,
      state == CallJobState.done ? ToolRunState.done : ToolRunState.failed,
    );
  }

  static String _short(String s, int max) {
    final t = s.trim().replaceAll(RegExp(r'\s+'), ' ');
    return t.length <= max ? t : '${t.substring(0, max)}…';
  }

  /// A note for the bot about a job, said once nobody is speaking (decision 8).
  void _tell(String note) {
    _notes.add(note);
    _armNotes();
  }

  /// Waits for a pause: any speech, either side, starts the wait again.
  void _armNotes() {
    _noteTimer?.cancel();
    _noteTimer = Timer(pauseBeforeNote, _deliverNotes);
  }

  void _deliverNotes() {
    _noteTimer = null;
    final call = _call;
    if (_notes.isEmpty || call == null || over || _ending) return;
    if (call.speaking.value || _held) {
      _armNotes();
      return;
    }
    call.tellModel(_notes.join('\n'));
    _notes.clear();
  }

  /// Shows a finished tool for a moment, then folds it away.
  void _settle(ToolRun run, ToolRunState state) {
    if (over) return;
    run.state = state;
    toolHaptic(state);
    _changed();
    if (!run.settled) return;
    final linger = switch (state) {
      ToolRunState.failed ||
      ToolRunState.background => const Duration(seconds: 5),
      _ => const Duration(milliseconds: 2600),
    };
    late final Timer t;
    t = Timer(linger, () {
      _fades.remove(t);
      runs.remove(run);
      _changed();
    });
    _fades.add(t);
  }

  /// Allow or Not now, from a card: decides the approval and tells the bot, which carries on.
  /// Throws when the decision couldn't be sent (the card shows the error).
  Future<void> decide(ToolRun run, bool allow) async {
    final id = run.approvalId;
    if (id == null) return;
    run.deciding = true;
    _changed();
    try {
      await backend.decideApproval(id, approve: allow);
      // Intentionally not translated: this goes to the voice model, not the user.
      _call?.tellModel(
        allow
            ? '(The user approved ${run.key} in the app. It is running now; the result will appear in the chat. Tell them briefly and carry on.)'
            : '(The user declined ${run.key} in the app. Acknowledge it briefly and carry on.)',
      );
      final job = jobs.where((j) => j.card == run).firstOrNull;
      if (job != null) {
        // A job's approval: it carries on (or stops, and its events say so).
        if (job.state == CallJobState.needsApproval) job.state = CallJobState.running;
        run
          ..state = ToolRunState.running
          ..approvalId = null
          ..deciding = false;
        _changed();
      } else {
        _settle(run, allow ? ToolRunState.approved : ToolRunState.declined);
      }
    } catch (e) {
      run.deciding = false;
      _changed();
      rethrow;
    }
  }

  void setMuted(bool muted) {
    if (_muted == muted) return;
    _muted = muted;
    _call?.setMuted(muted);
    _syncSystem();
    _changed();
  }

  Future<void> _loadRoute() async {
    final routes = _call?.routes;
    if (routes == null) return;
    try {
      _route = await routes.current() ?? const CallRoute(CallRouteKind.speaker);
    } catch (_) {
      _route = const CallRoute(CallRouteKind.speaker);
    }
    _changed();
  }

  Future<void> selectRoute(CallRoute pick) async {
    _route = pick;
    _changed();
    await _call?.routes?.select(pick);
  }

  /// Ends the call, from anywhere: hangs up, saves what's left of the transcript with the call's
  /// length and usage, and ends the server's record. Safe to call more than once.
  Future<void> end(CallEnd reason) async {
    if (_ending || over) return;
    _ending = true;
    _idleTimer?.cancel();
    _heartbeat?.cancel();
    _maxWarnTimer?.cancel();
    _maxEndTimer?.cancel();
    _goodbyeTimer?.cancel();
    _noteTimer?.cancel();
    _tileDoneTimer?.cancel();
    for (final s in _jobSubs) {
      unawaited(s.cancel());
    }
    _jobSubs.clear();
    _changed();
    final call = _call;
    final usage = call?.usage;
    if (call != null) {
      call.transcript.removeListener(_onTranscript);
      _onTranscript();
      await call.hangUp();
    }
    await _endSystem();
    final seconds = connectedAt == null
        ? 0
        : DateTime.now().difference(connectedAt!).inSeconds;
    // A call that never connected already ended its record when it failed.
    if (_error == null &&
        (_liveCallId != null || (call != null && conversationId != null))) {
      // One more try for queued turns; whatever's still unsent goes with the hang-up.
      await _turns.flush();
      try {
        await _finishRecord(_turns.unsent, seconds, usage);
      } catch (e) {
        saveError = e;
      }
    }
    _turns.close();
    _endedBy = reason;
    _ending = false;
    _changed();
    onEnded?.call(this);
  }

  Future<void> _finishRecord(
    List<(String, String, String)> unsent,
    int seconds,
    Map<String, int>? usage,
  ) async {
    final conv = conversationId;
    if (conv == null) return;
    await backend.saveVoiceTranscript(
      conv,
      [for (final (_, role, text) in unsent) (role, text)],
      seconds,
      provider: _provider,
      usage: usage,
      liveCallId: _liveCallId,
      turnIds: [for (final (id, _, _) in unsent) id],
    );
  }

  var _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    for (final t in _fades) {
      t.cancel();
    }
    _idleTimer?.cancel();
    _heartbeat?.cancel();
    _maxWarnTimer?.cancel();
    _maxEndTimer?.cancel();
    _goodbyeTimer?.cancel();
    _noteTimer?.cancel();
    _tileDoneTimer?.cancel();
    for (final s in _jobSubs) {
      unawaited(s.cancel());
    }
    _turns.close();
    unawaited(_toolSub?.cancel());
    unawaited(_endSystem());
    final call = _call;
    if (call != null) {
      call.state.removeListener(_onState);
      call.speaking.removeListener(_changed);
      call.reconnecting?.removeListener(_changed);
      call.reconnecting?.removeListener(_syncSystem);
      call.transcript.removeListener(_changed);
      call.replyLatencyMs.removeListener(_changed);
      call.transcript.removeListener(_activity);
      call.speaking.removeListener(_activity);
      call.transcript.removeListener(_onTranscript);
      if (!over) unawaited(call.hangUp());
    }
    super.dispose();
  }
}

/// The one call the app has (D-327 §2): no call, or one call, whichever screen is open. Every call
/// entry point (the call button, `/bots/:botId/call` links, the wake word, answering a ring) opens
/// the call screen, which asks this for the call.
class ActiveCall extends ChangeNotifier {
  ActiveCall(
    this._backend,
    this._connector, {
    this.computerOf,
    this.openPath,
    this.botNameOf,
    this.botAvatarOf,
    CallSystem Function()? system,
    this.interruptionsOf,
  }) : _system = system ?? NoCallSystem.new;

  /// The phone's call controls, one per call (D-327 §7).
  final CallSystem Function() _system;

  /// The interruption listener, one per call (null where there's none).
  final CallInterruptions? Function()? interruptionsOf;

  /// A bot's name, for the phone's call controls.
  final String Function(String botId)? botNameOf;

  /// A bot's icon (`avatar_url`), for the phone's call notification.
  final String? Function(String botId)? botAvatarOf;
  final Backend Function() _backend;
  final VoiceCallConnector Function() _connector;

  /// The computer a bot uses (the app's computer list), for showing its screen on a call.
  final String? Function(String botId)? computerOf;

  /// Opens a page: [swap] replaces the call screen (the call shrinks to the bubble), otherwise
  /// it's pushed over whatever is open.
  final void Function(String path, {bool swap})? openPath;

  /// `show_screen` (D-327 §6): the tile on the call screen, or the full live view when the tile
  /// already shows or the call is minimised. Returns what to tell the bot.
  String _showScreen(CallController c) {
    // Intentionally not translated: these go to the voice model, not the user.
    final id = c.jobComputerId ?? computerOf?.call(c.botId);
    if (id == null) {
      return "There's no computer screen to show right now. Tell the user.";
    }
    if (!onScreen || c.tileShown) {
      openPath?.call(liveViewPath(id), swap: onScreen);
      return "The user's app now shows your computer's screen full size. Tell them in a few words.";
    }
    c.showTile();
    return "Your computer's screen now shows in a small tile on the call. Tell the user they can tap it to see it full size.";
  }

  CallController? _current;

  /// The call going on (or ending), if any.
  CallController? get current => _current;

  /// A call going on that isn't over yet.
  CallController? get live {
    final c = _current;
    return c == null || c.over ? null : c;
  }

  /// The last call that ended, for its recap (cleared by the next call).
  CallController? lastEnded;

  var _views = 0;
  var _docks = 0;

  /// The sidebar card shows the call (wide windows): the bubble stays away.
  bool get docked => _docks > 0;

  void addDock() {
    _docks++;
    _notifySoon();
  }

  void removeDock() {
    _docks = _docks > 0 ? _docks - 1 : 0;
    _notifySoon();
  }

  /// A call screen shows the call now (the bubble and the sidebar card step aside).
  bool get onScreen => _views > 0;

  void addView() {
    _views++;
    _notifySoon();
  }

  void removeView() {
    _views = _views > 0 ? _views - 1 : 0;
    _notifySoon();
  }

  var _closed = false;

  /// Views come and go while widgets build and unmount: tell listeners just after.
  void _notifySoon() => scheduleMicrotask(() {
    if (!_closed) notifyListeners();
  });

  /// Starts a call with [botId], unless one is going on: the same bot's call is returned as it is,
  /// and another bot's call returns null (the caller asks "End call with Ava and call Max?" first).
  CallController? begin(
    String botId, {
    String? conversationId,
    String? phoneCallId,
    Duration idleLimit = const Duration(minutes: 1),
  }) {
    final now = live;
    if (now != null) return now.botId == botId ? now : null;
    _drop();
    final c = CallController(
      backend: _backend(),
      connector: _connector(),
      botId: botId,
      requestedConversationId: conversationId,
      phoneCallId: phoneCallId,
      idleLimit: idleLimit,
      onEnded: _ended,
      onShowScreen: _showScreen,
      system: _system(),
      interruptions: interruptionsOf?.call(),
      botName: botNameOf?.call(botId) ?? '',
      botAvatar: botAvatarOf?.call(botId),
      onOpen: (c) => openPath?.call(callPath(c)),
    );
    c.addListener(notifyListeners);
    _current = c;
    lastEnded = null;
    unawaited(c.connect());
    // Call screens start calls from initState, while the tree builds.
    _notifySoon();
    return c;
  }

  void _ended(CallController c) {
    if (_current != c) return;
    lastEnded = c;
    notifyListeners();
  }

  /// Ends the call going on, if any, and waits until it's saved.
  Future<void> end([CallEnd reason = CallEnd.hungUp]) async {
    await live?.end(reason);
  }

  /// Carries out a button from outside the app's window (the lock screen, the menu bar).
  void act(CallSystemAction action) {
    final c = live;
    if (c == null) return;
    switch (action) {
      case CallSystemAction.mute:
        c.setMuted(true);
      case CallSystemAction.unmute:
        c.setMuted(false);
      case CallSystemAction.end:
        unawaited(c.end(CallEnd.hungUp));
      case CallSystemAction.open:
        openPath?.call(callPath(c));
      case CallSystemAction.hold:
      case CallSystemAction.resume:
        break;
    }
  }

  /// Forgets an ended call (its screen is gone).
  void clearEnded() {
    final c = _current;
    if (c != null && c.over) {
      _drop();
      _notifySoon();
    }
  }

  void _drop() {
    final c = _current;
    if (c == null) return;
    c.removeListener(notifyListeners);
    _current = null;
    // Dispose after listeners are done with this frame's notifications.
    scheduleMicrotask(c.dispose);
  }

  @override
  void dispose() {
    _closed = true;
    final c = _current;
    _current = null;
    if (c != null) {
      c.removeListener(notifyListeners);
      c.dispose();
    }
    super.dispose();
  }
}

/// The app's one call, alive for the app's life (D-327).
final activeCallProvider = Provider<ActiveCall>((ref) {
  final a = ActiveCall(
    () => ref.read(backendProvider),
    () => ref.read(voiceCallConnectorProvider),
    computerOf: (botId) => computerForBot(
      ref.read(computersProvider).value ?? const [],
      botId,
      defaultComputerId: ref.read(botProvider(botId))?.defaultComputerId,
    )?.id,
    botNameOf: (botId) => ref.read(botProvider(botId))?.name ?? 'Casama',
    botAvatarOf: (botId) => ref.read(botProvider(botId))?.avatarUrl,
    system: () => ref.read(callSystemProvider)(),
    interruptionsOf: () => ref.read(callInterruptionsProvider)(),
    openPath: (path, {swap = false}) {
      final router = ref.read(routerProvider);
      if (swap) {
        router.swapTo(path);
      } else {
        unawaited(router.pushOnce(path));
      }
    },
  );
  ref.onDispose(a.dispose);
  return a;
});

/// A call's screen (its route in the app).
String callPath(CallController c) =>
    '/bots/${c.botId}/call${c.conversationId == null ? '' : '?c=${c.conversationId}'}';

/// The full live view of a computer (its route in the app).
String liveViewPath(String computerId) => '/computer/live?c=$computerId';

/// Makes the phone's call controls for each call (overridden in tests).
final callSystemProvider = Provider<CallSystem Function()>(
  (_) => deviceCallSystem,
);

/// Makes the interruption listener for each call (overridden in tests).
final callInterruptionsProvider = Provider<CallInterruptions? Function()>(
  (_) => deviceCallInterruptions,
);

import 'dart:async';
import 'dart:convert';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/chat_focus.dart';
import '../../core/providers.dart';
import 'app_browser_channel.dart';
import 'app_browser_sites.dart';
import 'app_browser_socket.dart';

/// Where a bot's use of the phone browser is (PROTOCOL.md §1, plan §4).
enum AppBrowserPhase {
  /// No bot is using it (the page may still be there).
  idle,

  /// A bot is driving the page.
  working,

  /// A site ask or a step ask is waiting for the person.
  asking,

  /// The bot handed the page to the person ("Your turn").
  yourTurn,

  /// The person touched the page or tapped Take Over: the bot waits for Hand Back.
  tookOver,

  /// The run's chat left the screen (or the app went to the background) while a bot was using it.
  away,
}

enum AppBrowserAskKind { site, step }

/// What the person is being asked.
class AppBrowserAsk {
  const AppBrowserAsk.site({
    required this.botName,
    required String this.host,
    this.siteKind,
    this.conversationId,
  }) : kind = AppBrowserAskKind.site,
       reason = null,
       step = null,
       name = null;

  const AppBrowserAsk.step({
    required this.botName,
    this.reason,
    this.step,
    this.name,
    this.conversationId,
  }) : kind = AppBrowserAskKind.step,
       host = null,
       siteKind = null;

  final AppBrowserAskKind kind;
  final String botName;
  final String? conversationId;

  /// A site ask: the site, and the off-by-default kind when one was switched back on.
  final String? host;
  final String? siteKind;

  /// A step ask: why the server asks (`args.reason`), the step ("click", "fill", "press") and the
  /// element's name.
  final String? reason;
  final String? step;
  final String? name;
}

/// The person's answer to a site ask.
enum AppBrowserSiteAnswer { once, always, never }

/// What the phone browser shows: who is using it, where it is, what is asked.
@immutable
class AppBrowserSession {
  const AppBrowserSession({
    this.phase = AppBrowserPhase.idle,
    this.run,
    this.url,
    this.title = '',
    this.loading = false,
    this.canGoBack = false,
    this.canGoForward = false,
    this.ask,
    this.handoffReason,
    this.person = false,
  });

  final AppBrowserPhase phase;

  /// The run using the page; null when no bot is.
  final AppBrowserRun? run;
  final String? url;
  final String title;
  final bool loading;
  final bool canGoBack;
  final bool canGoForward;
  final AppBrowserAsk? ask;

  /// What "Your turn" says (`args.reason` of a handoff).
  final String? handoffReason;

  /// The person is browsing by hand (Sign In to a Site): no bot, only the first two gate steps.
  final bool person;

  /// A bot is using the page now (working, asking, handed it over, or paused by the person).
  bool get botActive =>
      run != null &&
      (phase == AppBrowserPhase.working ||
          phase == AppBrowserPhase.asking ||
          phase == AppBrowserPhase.yourTurn ||
          phase == AppBrowserPhase.tookOver);

  String? get conversationId => run?.conversationId;
  String? get host {
    final u = url;
    if (u == null || u == 'about:blank') return null;
    final h = hostOf(u);
    return h == null || h.isEmpty ? null : h;
  }

  bool get secure => url?.toLowerCase().startsWith('https://') ?? false;

  AppBrowserSession copyWith({
    AppBrowserPhase? phase,
    AppBrowserRun? run,
    bool clearRun = false,
    String? url,
    bool clearUrl = false,
    String? title,
    bool? loading,
    bool? canGoBack,
    bool? canGoForward,
    AppBrowserAsk? ask,
    bool clearAsk = false,
    String? handoffReason,
    bool clearHandoff = false,
    bool? person,
  }) => AppBrowserSession(
    phase: phase ?? this.phase,
    run: clearRun ? null : run ?? this.run,
    url: clearUrl ? null : url ?? this.url,
    title: title ?? this.title,
    loading: loading ?? this.loading,
    canGoBack: canGoBack ?? this.canGoBack,
    canGoForward: canGoForward ?? this.canGoForward,
    ask: clearAsk ? null : ask ?? this.ask,
    handoffReason: clearHandoff ? null : handoffReason ?? this.handoffReason,
    person: person ?? this.person,
  );
}

/// How long the phone waits for the person and the page (PROTOCOL.md §1).
class AppBrowserTimings {
  const AppBrowserTimings({
    this.ask = const Duration(minutes: 5),
    this.takeOver = const Duration(minutes: 8),
    this.settle = const Duration(seconds: 15),
    this.dialog = const Duration(seconds: 30),
    this.commandMs = 30000,
  });

  /// A site or step ask with no answer counts as no.
  final Duration ask;

  /// Calls wait this long for Hand Back after the person took over.
  final Duration takeOver;

  /// `open` waits this long for the page to settle.
  final Duration settle;

  /// A page dialog the bot doesn't answer is dismissed.
  final Duration dialog;
  final int commandMs;
}

final appBrowserTimingsProvider = Provider<AppBrowserTimings>(
  (ref) => const AppBrowserTimings(),
);

/// The lists shipped with the app (PROTOCOL.md §2).
final appBrowserGuardProvider = FutureProvider<AppBrowserGuard>(
  (ref) => AppBrowserGuard.load(),
);

/// Hosts the server added to the kinds without a release; none when the server can't say.
final appBrowserExtraSitesProvider = FutureProvider<Map<String, List<String>>>(
  (ref) => ref
      .watch(backendProvider)
      .browserGuardSites()
      .catchError((_) => const <String, List<String>>{}),
);

/// The conversation on screen in this app now (null when no chat is open or the app is behind).
final appBrowserFocusProvider = Provider<String? Function()>((ref) {
  final focus = ref.watch(chatFocusProvider);
  return () => focus.conversation;
});

/// Page-script codes passed through to the bot as they are.
const _passThroughCodes = {
  'stale_ref',
  'covered',
  'page_changed',
  'not_editable',
  'not_file_input',
  'too_large',
  'out_of_sight',
  'unsupported',
};

/// Runs the phone browser: answers the server's calls (PROTOCOL.md §1's table), runs the site gate
/// before pages load, asks the person, and pauses when they take over. Native's events come here
/// (it is the channel's handler).
class AppBrowserController extends Notifier<AppBrowserSession>
    implements AppBrowserNativeEvents {
  late AppBrowserChannel _channel;
  AppSitePolicy _policy = const AppSitePolicy();
  AppBrowserSupport? _support;

  // The run using the page, and the sites the person answered "once" in it.
  String? _runId;
  final _once = <String>[];
  final _stopped = <String>{};
  final _addedAllowed = <String>{};
  final _addedBlocked = <String>{};

  Completer<String>? _askAnswer;
  Future<void> _askQueue = Future.value();
  Completer<bool>? _handBack;
  Completer<_Nav>? _nav;
  ({String kind, String message})? _dialog;
  Timer? _dialogTimer;
  DateTime? _ownTapAt;
  var _pageLost = false;
  var _seq = 0;

  @override
  AppBrowserSession build() {
    _channel = ref.watch(appBrowserChannelProvider);
    _channel.setHandler(this);
    ref.onDispose(() {
      _channel.setHandler(null);
      _dialogTimer?.cancel();
      _endRun(answer: 'away');
    });
    return const AppBrowserSession();
  }

  AppBrowserTimings get _timings => ref.read(appBrowserTimingsProvider);

  void _set(AppBrowserSession s) {
    if (ref.mounted) state = s;
  }

  /// The paired device whose lists "Always" and "Never" change (the service keeps it current).
  LocalDevice? device;

  /// What this phone's web area can do; asked once.
  Future<AppBrowserSupport> support() async =>
      _support ??= await _channel.supported();

  // --- the server's calls ---------------------------------------------------------------------

  /// Answers one call with a `BrowserResult`.
  Future<Map<String, Object?>> handle(AppBrowserCall call) async {
    final run = call.run;
    if (const {'console', 'network', 'page_text'}.contains(call.action)) {
      return _fail(
        'unsupported',
        "That isn't available in the phone's browser; use your own computer for it.",
      );
    }
    if (_stopped.contains(run.id)) {
      return _fail(
        'away',
        'The person stopped you using the browser on their phone. Carry on with your own computer, or ask them.',
      );
    }
    if (!_onScreen(run)) {
      if (_runId == run.id) _goAway();
      return _away();
    }
    if (_runId != run.id) _startRun(run);
    _policy = call.policy.plus(allowed: _addedAllowed, blocked: _addedBlocked);
    if (call.action != 'stop' &&
        call.action != 'handoff' &&
        _waitingForPerson) {
      if (!await _waitForHandBack(call)) {
        if (_runId == run.id) _goAway();
        return _fail(
          'away',
          "The person took over the page on their phone and hasn't handed it back. Carry on with your own computer, or ask them.",
        );
      }
    }
    if (state.phase == AppBrowserPhase.idle ||
        state.phase == AppBrowserPhase.away ||
        state.run?.id != run.id) {
      _set(
        state.copyWith(
          phase: AppBrowserPhase.working,
          run: run,
          person: false,
          clearAsk: true,
        ),
      );
    }
    try {
      return await _dispatch(call);
    } on PlatformException catch (e) {
      return _fail('error', e.message ?? e.code);
    } on MissingPluginException {
      return _fail('unsupported', "This phone's app has no browser.");
    } catch (e) {
      return _fail('error', '$e');
    }
  }

  bool get _waitingForPerson =>
      ref.mounted && state.phase == AppBrowserPhase.tookOver ||
      state.phase == AppBrowserPhase.yourTurn;

  Future<Map<String, Object?>> _dispatch(AppBrowserCall call) async {
    final a = call.args;
    switch (call.action) {
      case 'open':
        return _open('${a['url'] ?? ''}', call);
      case 'switch_tab':
        final url = a['url'] as String?;
        if (url != null && url.isNotEmpty) return _open(url, call);
        return _ok('There is one page on the phone.', url: state.url);
      case 'snapshot' || 'read' || 'extract' || 'scroll' || 'wait':
        if (_pageLost) return _lost();
        return _pageResult(await _command(call.action, a));
      case 'url':
        final p = await _refreshPage();
        return _ok(p.url, url: p.url);
      case 'probe':
        if (_pageLost) return _lost();
        final r = await _command('probe', a);
        if (r['ok'] != true) return _pageFail(r);
        return _ok(
          jsonEncode({'facts': r['facts'], 'fingerprint': r['fingerprint']}),
        );
      case 'ask':
        final answer = await _askPerson(
          AppBrowserAsk.step(
            botName: call.run.botName,
            reason: a['reason'] as String?,
            step: a['step'] as String?,
            name: a['name'] as String?,
            conversationId: call.run.conversationId,
          ),
          call,
        );
        return _ok(switch (answer) {
          'allow' => 'allow',
          'timeout' => 'timeout',
          _ => 'deny',
        });
      case 'handoff':
        _handBack ??= Completer<bool>();
        _set(
          state.copyWith(
            phase: AppBrowserPhase.yourTurn,
            handoffReason: '${a['reason'] ?? ''}',
          ),
        );
        return _ok('shown');
      case 'click':
        return _click(call);
      case 'fill' || 'type' || 'press':
        if (_pageLost) return _lost();
        return _pageResult(
          await _command(call.action, {...a, 'fingerprint': ?call.expect}),
        );
      case 'upload':
        if (_pageLost) return _lost();
        final file = (a['file'] as Map?)?.cast<String, dynamic>() ?? const {};
        return _pageResult(
          await _command('upload', {
            'ref': a['ref'],
            'name': file['name'],
            'media_type': file['media_type'],
            'data': file['data'],
          }),
        );
      case 'download':
        if (_pageLost) return _lost();
        final url = '${a['url'] ?? ''}';
        final gate = await _gateForBot(url, call);
        if (gate != null) return gate;
        final r = await _command('download', {'url': url});
        if (r['ok'] != true) return _pageFail(r);
        final file = (r['file'] as Map?)?.cast<String, dynamic>();
        return {
          'ok': true,
          'text': 'Downloaded ${file?['name'] ?? 'the file'}',
          'file': ?file,
        };
      case 'screenshot':
        final data = await _channel.screenshot(
          quality: (a['quality'] as num?)?.toInt() ?? 70,
        );
        if (data == null) {
          return _fail('error', 'There is no picture of the page yet.');
        }
        return {
          'ok': true,
          'text': '',
          'image': {'data': data, 'media_type': 'image/jpeg'},
        };
      case 'dialog':
        final d = _dialog;
        if (d == null) return _fail('error', 'No dialog is open on the page.');
        _dialog = null;
        _dialogTimer?.cancel();
        await _channel.answerDialog(
          accept: a['accept'] != false,
          text: a['text'] as String?,
        );
        return _ok('Answered the ${d.kind} "${d.message}".');
      case 'tabs':
        final p = await _refreshPage();
        return _ok('1: ${p.title} ${p.url} (current)', url: p.url);
      case 'stop':
        _set(
          state.copyWith(
            phase: AppBrowserPhase.idle,
            clearRun: true,
            clearAsk: true,
            clearHandoff: true,
          ),
        );
        return _ok('Done');
      default:
        return _fail(
          'unsupported',
          "The phone's browser can't do ${call.action}.",
        );
    }
  }

  Future<Map<String, Object?>> _open(String url, AppBrowserCall call) async {
    final gate = await _gateForBot(url, call);
    if (gate != null) return gate;
    _pageLost = false;
    final nav = _nav = Completer<_Nav>();
    _set(state.copyWith(url: url, loading: true));
    await _channel.load(url);
    final outcome = await _race(
      nav.future,
      _timings.settle,
      const _Nav.settled(),
      call.cancelled,
      const _Nav.settled(),
    );
    if (identical(_nav, nav)) _nav = null;
    if (outcome.refused != null) return _refusedResult(outcome.refused!);
    if (outcome.denied != null) {
      return _fail(
        'asked_denied',
        'The person said no to ${outcome.denied} on their phone. Don\'t try it another way.',
      );
    }
    if (outcome.error != null) return _fail('error', outcome.error!);
    final p = await _refreshPage();
    return _ok('Opened ${p.title.isEmpty ? p.url : p.title}', url: p.url);
  }

  Future<Map<String, Object?>> _click(AppBrowserCall call) async {
    if (_pageLost) return _lost();
    final a = call.args;
    final real = (await support()).realTaps;
    if (!real) {
      return _pageResult(
        await _command('click', {
          ...a,
          'fingerprint': ?call.expect,
          'synthetic': true,
        }),
      );
    }
    final at = await _command('locate', {
      'ref': a['ref'],
      'fingerprint': ?call.expect,
    });
    if (at['ok'] != true) return _pageFail(at);
    _ownTapAt = DateTime.now();
    await _channel.tap(
      (at['x'] as num).toDouble(),
      (at['y'] as num).toDouble(),
    );
    return _pageResult(
      await _command('click', {
        ...a,
        'fingerprint': ?call.expect,
        'synthetic': false,
      }),
    );
  }

  /// The gate for a bot's step on [url]; null when it may go ahead, else the answer to send.
  Future<Map<String, Object?>?> _gateForBot(
    String url,
    AppBrowserCall call,
  ) async {
    final decision = await _decide(url);
    switch (decision) {
      case AppSiteAllowed():
        return null;
      case AppSiteRefused():
        return _refusedResult(decision);
      case AppSiteAsk(:final host, :final siteKind):
        final answer = await _askSite(host, siteKind, call.run, call);
        if (answer == AppBrowserSiteAnswer.once ||
            answer == AppBrowserSiteAnswer.always) {
          return null;
        }
        return _fail(
          'asked_denied',
          'The person said no to $host on their phone. Don\'t try it another way.',
        );
    }
  }

  Map<String, Object?> _refusedResult(
    AppSiteRefused r,
  ) => _fail('refused', switch (r.why) {
    'not_web' => "The phone's browser opens web pages only (http or https).",
    'casama' => "Casama's own pages can't be opened in the phone's browser.",
    'blocked' => '${r.host} is on the never list; the phone won\'t open it.',
    _ =>
      '${r.host} is a ${r.why} site, which is off in the phone\'s browser unless the person turns it on.',
  });

  Future<AppSiteDecision> _decide(String url) async {
    final guard = await ref.read(appBrowserGuardProvider.future);
    final extra = await ref
        .read(appBrowserExtraSitesProvider.future)
        .catchError((_) => const <String, List<String>>{});
    return appSiteDecision(url, _policy, guard, once: _once, extra: extra);
  }

  // --- asks ------------------------------------------------------------------------------------

  Future<AppBrowserSiteAnswer?> _askSite(
    String host,
    String? siteKind,
    AppBrowserRun run, [
    AppBrowserCall? call,
  ]) async {
    final answer = await _askPerson(
      AppBrowserAsk.site(
        botName: run.botName,
        host: host,
        siteKind: siteKind,
        conversationId: run.conversationId,
      ),
      call,
    );
    final a = AppBrowserSiteAnswer.values
        .where((v) => v.name == answer)
        .firstOrNull;
    switch (a) {
      case AppBrowserSiteAnswer.once:
        _once.add(host);
      case AppBrowserSiteAnswer.always:
        _once.add(host);
        _addedAllowed.add(host);
        _policy = _policy.plus(allowed: [host]);
        unawaited(_saveSite(host, always: true));
      case AppBrowserSiteAnswer.never:
        _addedBlocked.add(host);
        _policy = _policy.plus(blocked: [host]);
        unawaited(_saveSite(host, always: false));
      case null:
        break;
    }
    return a;
  }

  /// Shows [ask] and waits for the person, up to the ask timeout ("timeout"), a cancelled call or
  /// the run ending ("away"). One ask at a time.
  Future<String> _askPerson(AppBrowserAsk ask, [AppBrowserCall? call]) {
    final turn = _askQueue.then((_) async {
      if (call != null && call.isCancelled) return 'away';
      final answer = _askAnswer = Completer<String>();
      final before = state.phase;
      _set(state.copyWith(phase: AppBrowserPhase.asking, ask: ask));
      final result = await _race(
        answer.future,
        _timings.ask,
        'timeout',
        call?.cancelled,
        'away',
      );
      if (identical(_askAnswer, answer)) _askAnswer = null;
      if (state.phase == AppBrowserPhase.asking) {
        _set(
          state.copyWith(
            phase: before == AppBrowserPhase.asking
                ? AppBrowserPhase.working
                : before,
            clearAsk: true,
          ),
        );
      }
      return result;
    });
    _askQueue = turn.then((_) {}, onError: (_) {});
    return turn;
  }

  /// The person's answer to the site ask on screen.
  void answerSite(AppBrowserSiteAnswer answer) => _answer(answer.name);

  /// The person's answer to the step ask on screen.
  void answerStep(bool allow) => _answer(allow ? 'allow' : 'deny');

  void _answer(String value) {
    final a = _askAnswer;
    if (a != null && !a.isCompleted) a.complete(value);
  }

  Future<void> _saveSite(String host, {required bool always}) async {
    final d = device;
    if (d == null) return;
    final allowed = [...?d.allowedSites];
    final blocked = [...?d.blockedSites];
    if (always) {
      blocked.remove(host);
      if (!allowed.contains(host)) allowed.add(host);
    } else {
      allowed.remove(host);
      if (!blocked.contains(host)) blocked.add(host);
    }
    try {
      device = await ref
          .read(backendProvider)
          .updateAppBrowser(d.id, allowedSites: allowed, blockedSites: blocked);
    } catch (e) {
      debugPrint('phone browser: saving $host failed: $e');
    }
  }

  // --- the person's controls -------------------------------------------------------------------

  /// Take Over: the bot waits until Hand Back.
  void takeOver() {
    if (!ref.mounted || !state.botActive || _waitingForPerson) return;
    _handBack ??= Completer<bool>();
    _set(state.copyWith(phase: AppBrowserPhase.tookOver));
  }

  /// Hand Back: the bot carries on.
  void handBack() {
    if (!ref.mounted || !_waitingForPerson) return;
    final h = _handBack;
    _handBack = null;
    _set(state.copyWith(phase: AppBrowserPhase.working, clearHandoff: true));
    if (h != null && !h.isCompleted) h.complete(true);
  }

  /// Stop: the bot's run can't use the phone any more; the page stays.
  void stopBot() {
    final id = _runId;
    if (id == null || !ref.mounted) return;
    _stopped.add(id);
    _endRun(answer: 'away');
    unawaited(_channel.stop().catchError((_) {}));
    _set(
      state.copyWith(
        phase: AppBrowserPhase.idle,
        clearRun: true,
        clearAsk: true,
        clearHandoff: true,
        loading: false,
      ),
    );
  }

  /// The chat [conversationId] left the screen: a run working from it is away.
  void leftChat(String? conversationId) {
    if (!ref.mounted) return;
    if (conversationId != null &&
        state.run?.conversationId == conversationId &&
        state.botActive) {
      _goAway();
    }
  }

  /// The socket closed (the app went behind, the feature was switched off): whatever waited is away.
  void disconnected() {
    if (ref.mounted && state.botActive) _goAway();
  }

  /// Opens the browser for the person (Sign In to a Site).
  Future<void> openForPerson([String? url]) async {
    if (!ref.mounted) return;
    _set(state.copyWith(person: true));
    if (url != null) await loadForPerson(url);
  }

  void closePerson() {
    if (ref.mounted) _set(state.copyWith(person: false));
  }

  /// An address typed by the person; a bare host gets https.
  Future<bool> loadForPerson(String raw) async {
    var url = raw.trim();
    if (url.isEmpty) return false;
    if (!RegExp(r'^[a-z][a-z0-9+.\-]*:', caseSensitive: false).hasMatch(url)) {
      url = 'https://$url';
    }
    final guard = await ref.read(appBrowserGuardProvider.future);
    if (personSiteDecision(url, guard, ownUrls: _policy.ownUrls)
        is! AppSiteAllowed) {
      return false;
    }
    _set(state.copyWith(url: url, loading: true));
    await _channel.load(url);
    return true;
  }

  Future<void> back() => _channel.back();
  Future<void> forward() => _channel.forward();
  Future<void> reload() => _channel.reload();

  /// "Let My Bots Use This Site": the page's site joins this phone's always list.
  Future<String?> allowCurrentSite() async {
    final url = state.url;
    final host = url == null ? null : cleanSitePattern(hostOf(url) ?? '');
    if (host == null) return null;
    _addedAllowed.add(host);
    await _saveSite(host, always: true);
    return host;
  }

  /// Clears cookies and site data: one site, or everything.
  Future<void> clearData({String? host}) => _channel.clearData(host: host);

  /// A small picture of the page for the floating card; null when there is none.
  Future<Uint8List?> picture() async {
    try {
      final data = await _channel.screenshot(quality: 50);
      return data == null ? null : base64Decode(data);
    } catch (_) {
      return null;
    }
  }

  // --- native's events -------------------------------------------------------------------------

  @override
  Future<bool> navigate(
    String url, {
    required bool redirect,
    required bool user,
  }) async {
    if (url == 'about:blank') return true;
    final decision = await _navDecision(url, user: user);
    return decision;
  }

  @override
  Future<bool> landed(String url) async {
    final ok = await _navDecision(url, user: false, landing: true);
    if (!ok) _set(state.copyWith(url: 'about:blank'));
    return ok;
  }

  Future<bool> _navDecision(
    String url, {
    required bool user,
    bool landing = false,
  }) async {
    final guard = await ref.read(appBrowserGuardProvider.future);
    // The person's own browsing, and pages they open by touch: only the first two steps.
    if (state.person || user || !state.botActive) {
      final d = personSiteDecision(url, guard, ownUrls: _policy.ownUrls);
      if (d is AppSiteRefused) _completeNav(_Nav.refused(d));
      return d is AppSiteAllowed;
    }
    final d = await _decide(url);
    switch (d) {
      case AppSiteAllowed():
        return true;
      case AppSiteRefused():
        _completeNav(_Nav.refused(d));
        return false;
      case AppSiteAsk(:final host, :final siteKind):
        final run = state.run!;
        final answer = await _askSite(host, siteKind, run);
        final ok =
            answer == AppBrowserSiteAnswer.once ||
            answer == AppBrowserSiteAnswer.always;
        if (!ok) _completeNav(_Nav.denied(host));
        return ok;
    }
  }

  void _completeNav(_Nav outcome) {
    final nav = _nav;
    if (nav != null && !nav.isCompleted) nav.complete(outcome);
  }

  @override
  void pageStarted(String url) => _set(state.copyWith(url: url, loading: true));

  @override
  void pageFinished(String url, String title) {
    _set(state.copyWith(url: url, title: title, loading: false));
    _completeNav(const _Nav.settled());
    unawaited(_refreshPage().then((_) {}, onError: (_) {}));
  }

  @override
  void userTouched() {
    // Native's own tap for a bot's click isn't the person.
    final own = _ownTapAt;
    if (own != null &&
        DateTime.now().difference(own) < const Duration(milliseconds: 800)) {
      return;
    }
    if (state.phase == AppBrowserPhase.working && state.botActive) takeOver();
  }

  @override
  void dialog(String kind, String message) {
    _dialog = (kind: kind, message: message);
    _dialogTimer?.cancel();
    _dialogTimer = Timer(_timings.dialog, () {
      if (_dialog == null) return;
      _dialog = null;
      unawaited(_channel.answerDialog(accept: false).catchError((_) {}));
    });
  }

  @override
  void gone(String reason) {
    _pageLost = true;
    _completeNav(
      const _Nav.error("The phone's page was closed by the system."),
    );
    _set(state.copyWith(url: 'about:blank', title: '', loading: false));
  }

  // --- helpers ---------------------------------------------------------------------------------

  bool _onScreen(AppBrowserRun run) {
    final c = run.conversationId;
    return c != null && c == ref.read(appBrowserFocusProvider)();
  }

  void _startRun(AppBrowserRun run) {
    // A call for a different run ends the earlier run's session.
    _endRun(answer: 'away');
    _runId = run.id;
    _once.clear();
    _set(
      state.copyWith(
        phase: AppBrowserPhase.working,
        run: run,
        clearAsk: true,
        clearHandoff: true,
        person: false,
      ),
    );
  }

  /// Ends the run's waits: a pending ask gets [answer], a wait for Hand Back gives up.
  void _endRun({required String answer}) {
    _answer(answer);
    final h = _handBack;
    _handBack = null;
    if (h != null && !h.isCompleted) h.complete(false);
  }

  void _goAway() {
    _endRun(answer: 'away');
    _set(state.copyWith(phase: AppBrowserPhase.away, clearAsk: true));
  }

  Future<bool> _waitForHandBack(AppBrowserCall call) async {
    final h = _handBack ??= Completer<bool>();
    return _race(h.future, _timings.takeOver, false, call.cancelled, false);
  }

  Future<Map<String, dynamic>> _command(
    String cmd,
    Map<String, dynamic> args,
  ) async {
    final answer = await _channel.command({
      'id': 'c${++_seq}',
      'cmd': cmd,
      'args': args,
    }, timeoutMs: _timings.commandMs);
    return answer;
  }

  Future<AppBrowserPage> _refreshPage() async {
    final p = await _channel.url();
    _set(
      state.copyWith(
        url: p.url,
        title: p.title,
        loading: p.loading,
        canGoBack: p.canGoBack,
        canGoForward: p.canGoForward,
      ),
    );
    return p;
  }

  Map<String, Object?> _pageResult(Map<String, dynamic> r) {
    if (r['ok'] != true) return _pageFail(r);
    return _ok('${r['text'] ?? ''}', url: (r['url'] as String?) ?? state.url);
  }

  Map<String, Object?> _pageFail(Map<String, dynamic> r) {
    final code = '${r['code'] ?? 'error'}';
    return _fail(
      _passThroughCodes.contains(code) ? code : 'error',
      '${r['message'] ?? 'The page script failed'}',
    );
  }

  Map<String, Object?> _lost() => _fail(
    'error',
    "The phone's page was closed by the system; open the address again.",
  );

  Map<String, Object?> _away() => _fail(
    'away',
    "The person's chat isn't open on their phone, so the phone's browser can't be used now. Carry on with your own computer, or wait for them.",
  );

  /// [main], or [onTimeout] after [after], or [onCancel] once [cancelled] completes; the timer is
  /// cancelled as soon as one of them wins.
  static Future<T> _race<T>(
    Future<T> main,
    Duration after,
    T onTimeout, [
    Future<void>? cancelled,
    T? onCancel,
  ]) {
    final c = Completer<T>();
    final timer = Timer(after, () {
      if (!c.isCompleted) c.complete(onTimeout);
    });
    main.then(
      (v) {
        if (!c.isCompleted) c.complete(v);
      },
      onError: (Object e, StackTrace st) {
        if (!c.isCompleted) c.completeError(e, st);
      },
    );
    cancelled?.then((_) {
      if (!c.isCompleted) c.complete(onCancel ?? onTimeout);
    });
    return c.future.whenComplete(timer.cancel);
  }

  static Map<String, Object?> _ok(String text, {String? url}) => {
    'ok': true,
    'text': text,
    'url': ?url,
  };
  static Map<String, Object?> _fail(String code, String message) => {
    'ok': false,
    'code': code,
    'message': message,
  };
}

/// How a navigation the bot started ended.
class _Nav {
  const _Nav.settled() : refused = null, denied = null, error = null;
  const _Nav.refused(AppSiteRefused this.refused) : denied = null, error = null;
  const _Nav.denied(String this.denied) : refused = null, error = null;
  const _Nav.error(String this.error) : refused = null, denied = null;
  final AppSiteRefused? refused;

  /// The site the person said no to on the way.
  final String? denied;
  final String? error;
}

final appBrowserProvider =
    NotifierProvider<AppBrowserController, AppBrowserSession>(
      AppBrowserController.new,
    );

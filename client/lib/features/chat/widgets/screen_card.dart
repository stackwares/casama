import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/analytics.dart';
import '../../../core/backend.dart';
import '../../../core/haptics.dart';
import '../../../core/providers.dart';
import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/shell_layout.dart';
import '../../../ui/screen_tile.dart';
import '../chat_controller.dart';
import '../chat_detail.dart';

/// Debug builds only: the screen card with a sample screen, to try its size, corners and states
/// on a phone before it's wired to real pictures (SCREEN-CARD-PLAN Phase 0). Turn it on with
/// `?previewScreenCard=1` on the web or `--dart-define=PREVIEW_SCREEN_CARD=1` on a device.
final bool screenCardPreview =
    kDebugMode && (Uri.base.queryParameters.containsKey('previewScreenCard') || const {'1', 'true'}.contains(_previewDefine));

const _previewDefine = String.fromEnvironment('PREVIEW_SCREEN_CARD');

/// How wide the card is: 38% of the chat on phones, between 132 and 168 points; 220 on tablets.
double screenCardWidth(double chatWidth, LayoutSize layout) => layout == LayoutSize.phone ? (chatWidth * 0.38).clamp(132.0, 168.0) : 220.0;

/// Tools that drive the screen: the bot's browser and its desktop. Terminal, file and checkpoint
/// steps have nothing to look at (SCREEN-CARD-PLAN §4), nor does searching files from the desktop.
bool isScreenTool(String tool) =>
    (tool.startsWith('browser.') || tool.startsWith('desktop.')) && !tool.startsWith('desktop.files');

/// What the chat says about the bot's screen since the person's last message (SCREEN-CARD-PLAN
/// §4), read from its entries.
@immutable
class ScreenWork {
  const ScreenWork({
    required this.reply,
    required this.running,
    required this.steps,
    required this.runningSteps,
    required this.takeoverComputer,
    required this.held,
    required this.failed,
    this.bot,
  });

  /// Which reply this is: the id of the person's last message ('' before any).
  final String reply;
  final bool running;

  /// Screen steps this reply has started, and those still going.
  final int steps;
  final Set<String> runningSteps;

  /// The computer a takeover request still waits on, if any.
  final String? takeoverComputer;

  /// A person holds the screen (the newest control notice says so).
  final bool held;

  /// The reply ended in a failure or was stopped.
  final bool failed;

  /// Which bot took the newest screen step, when the chat says (group chats).
  final String? bot;

  @override
  bool operator ==(Object other) =>
      other is ScreenWork &&
      other.reply == reply &&
      other.running == running &&
      other.steps == steps &&
      setEquals(other.runningSteps, runningSteps) &&
      other.takeoverComputer == takeoverComputer &&
      other.held == held &&
      other.failed == failed &&
      other.bot == bot;

  @override
  int get hashCode => Object.hash(reply, running, steps, Object.hashAllUnordered(runningSteps), takeoverComputer, held, failed, bot);

  static ScreenWork of(ChatState c) {
    var reply = '';
    var steps = 0;
    final runningSteps = <String>{};
    String? takeover;
    bool? held;
    var failed = false;
    String? bot;
    for (var i = c.entries.length - 1; i >= 0; i--) {
      final e = c.entries[i];
      if (e is MessageEntry && e.role == 'user') {
        reply = e.id;
        break;
      }
      if (e is ToolEntry && isScreenTool(e.tool)) {
        steps++;
        bot ??= e.botId;
        if (e.status == ToolStatus.running) runningSteps.add(e.callId);
      } else if (e is TakeoverEntry && e.outcome == null) {
        takeover ??= e.computerId;
      } else if (e is NoticeEntry) {
        if (held == null && e.kind == NoticeKind.userControl) held = true;
        if (held == null && e.kind == NoticeKind.botControl) held = false;
        if (e.kind == NoticeKind.failed || e.kind == NoticeKind.cancelled) failed = true;
      }
    }
    return ScreenWork(
      reply: reply,
      running: c.running,
      steps: steps,
      runningSteps: runningSteps,
      takeoverComputer: takeover,
      held: held ?? false,
      failed: failed,
      bot: bot,
    );
  }
}

/// The bot's screen in a corner of its chat while it works on it (SCREEN-CARD-PLAN). Fetches
/// small pictures about once a second, only while it might show; never wakes the computer. A tap
/// opens the full live view.
class ScreenCard extends ConsumerStatefulWidget {
  const ScreenCard({
    super.key,
    required this.botId,
    required this.botName,
    required this.computerId,
    required this.layout,
    required this.onOpen,
    this.computerFor,
    this.faceFor,
    this.nameFor,
  });
  final String botId;
  final String botName;

  /// The bot's own computer (a takeover request may name another).
  final String? computerId;
  final LayoutSize layout;
  final void Function(String computerId) onOpen;

  /// Group chats: the computer of the bot taking screen steps, and its face for the card.
  final String? Function(String botId)? computerFor;
  final Widget Function(String botId)? faceFor;
  final String Function(String botId)? nameFor;

  @override
  ConsumerState<ScreenCard> createState() => _ScreenCardState();
}

/// The timings in SCREEN-CARD-PLAN §4.
abstract final class ScreenCardTimes {
  /// One screen step that runs this long counts as more than a single look.
  static const longLook = Duration(seconds: 2);

  /// No screen step for this long while the reply goes on: the bot moved on.
  static const movedOn = Duration(seconds: 20);

  /// Once shown, it stays at least this long, so it never blinks.
  static const minShown = Duration(seconds: 6);
  static const done = Duration(seconds: 3);

  /// No new picture for this long: dimmed. For [gone]: hidden.
  static const stale = Duration(seconds: 8);
  static const gone = Duration(seconds: 20);

  /// The pause between one picture arriving and asking for the next.
  static const between = Duration(seconds: 1);

  /// How long the first-time line stays.
  static const intro = Duration(seconds: 4);
}

class _ScreenCardState extends ConsumerState<ScreenCard> with WidgetsBindingObserver {
  ScreenWork? _work;
  String? _closedReply;
  String? _shownReply;
  var _shown = false;
  var _done = false;
  var _stale = false;
  var _lookedLong = false;
  var _movedOn = false;
  var _minShownPassed = true;
  var _pictureGone = false;

  Uint8List? _picture;
  String? _etag;
  String? _pictureOf;
  var _polling = false;
  var _visible = true;

  Timer? _longLook;
  Timer? _movedOnTimer;
  Timer? _minShown;
  Timer? _doneTimer;
  Timer? _staleTimer;
  Timer? _goneTimer;
  Timer? _next;
  Timer? _back;
  Timer? _introTimer;

  /// Needs you was signalled (haptic, pulse, announcement) for this reply and computer.
  String? _signalled;
  var _pulse = 0;
  var _intro = false;
  var _introChecked = false;

  static const _introKey = 'screenCard.introSeen';
  static const _closesKey = 'screenCard.closesInARow';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(chatControllerProvider(widget.botId).select(ScreenWork.of), _onWork, fireImmediately: true);
    ref.listenManual(showScreenCardProvider, (_, _) => _update());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final t in [_longLook, _movedOnTimer, _minShown, _doneTimer, _staleTimer, _goneTimer, _next, _back, _introTimer]) {
      t?.cancel();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Nothing is fetched while nobody can see it.
    _visible = state == AppLifecycleState.resumed;
    _update();
  }

  /// Who the card is about: the bot taking the screen steps in a group chat.
  String get _botName {
    final bot = _work?.bot, name = widget.nameFor;
    return name != null && bot != null ? name(bot) : widget.botName;
  }

  String? get _computer {
    final w = _work;
    if (w?.takeoverComputer != null) return w!.takeoverComputer;
    final bot = w?.bot, pick = widget.computerFor;
    if (pick != null && bot != null) return pick(bot);
    return widget.computerId;
  }

  /// The chat changed: new steps, a finished reply, a takeover.
  void _onWork(ScreenWork? prev, ScreenWork next) {
    _work = next;
    // While someone holds the screen the bot waits: that's not moving on. Handed back, the
    // pictures start again, and so do the clocks.
    if (next.held) {
      _movedOnTimer?.cancel();
      _movedOn = false;
    } else if (prev?.held ?? false) {
      _freshPicture();
      _restartMovedOn();
    }
    // A reply the card showed through without being closed: the closes in a row start over.
    if ((prev?.running ?? false) && !next.running && _shownReply == next.reply && _closedReply != next.reply) {
      unawaited(_setCloses(0));
    }
    if (prev?.reply != next.reply) {
      // A new reply starts afresh: closing it hid only the last one.
      _lookedLong = false;
      _movedOn = false;
      _done = false;
      _doneTimer?.cancel();
      _longLook?.cancel();
    }
    final active = next.runningSteps.isNotEmpty || next.steps > (prev?.reply == next.reply ? prev!.steps : 0);
    if (active && !next.held) _restartMovedOn();
    if (next.runningSteps.isNotEmpty && !_lookedLong && (_longLook == null || !_longLook!.isActive)) {
      _longLook = Timer(ScreenCardTimes.longLook, () {
        if (_work?.runningSteps.isNotEmpty ?? false) _lookedLong = true;
        _update();
      });
    }
    // The reply ended: "Done" for a moment when it went well, at once when it didn't.
    if ((prev?.running ?? false) && !next.running && _shown && !next.failed) {
      _done = true;
      _doneTimer?.cancel();
      _doneTimer = Timer(ScreenCardTimes.done, () {
        _done = false;
        _update();
      });
    }
    _update();
  }

  void _restartMovedOn() {
    _movedOn = false;
    _movedOnTimer?.cancel();
    _movedOnTimer = Timer(ScreenCardTimes.movedOn, () {
      _movedOn = true;
      _update();
    });
  }

  /// Whether the chat calls for the card right now (SCREEN-CARD-PLAN §4), pictures aside.
  bool get _wanted {
    final w = _work;
    if (w == null || _computer == null || !_visible) return false;
    if (_closedReply == w.reply) return false;
    if (!ref.read(showScreenCardProvider)) return false;
    if (_done) return true;
    if (!w.running) return false;
    if (w.takeoverComputer != null || w.held) return true;
    if (w.steps == 0 || _movedOn) return false;
    return w.steps >= 2 || _lookedLong;
  }

  /// Set after the first frame: before it there's no route to ask about.
  var _ready = false;

  void _update() {
    if (!mounted || !_ready) return;
    final route = ModalRoute.of(context);
    // Under another page (the live view itself, say): no card and no fetching.
    final onTop = route == null || route.isCurrent;
    final wanted = _wanted && onTop;
    final id = _computer;
    if (id != _pictureOf) {
      _picture = null;
      _etag = null;
      _pictureOf = id;
    }
    // Someone holds the screen: the last picture stays, paused (§5), and nothing is fetched.
    final held = _work?.held ?? false;
    final fetch = wanted && !(held && _picture != null);
    if (fetch && !_polling) {
      _polling = true;
      unawaited(_fetch());
    }
    if (!fetch) {
      _polling = false;
      _next?.cancel();
    }
    if (held) {
      _staleTimer?.cancel();
      _goneTimer?.cancel();
      _stale = false;
      _pictureGone = false;
    }
    final show = wanted && _picture != null && !_pictureGone;
    // Once shown, it stays its minimum time unless the reply ended, it was closed or the page left.
    final keep = _shown && !show && !_minShownPassed && onTop && (_work?.running ?? false) && _closedReply != _work?.reply;
    final next = show || keep;
    if (next != _shown) {
      if (next) {
        _minShownPassed = false;
        _minShown?.cancel();
        _minShown = Timer(ScreenCardTimes.minShown, () {
          _minShownPassed = true;
          _update();
        });
        if (_shownReply != _work?.reply) {
          _shownReply = _work?.reply;
          Analytics.log('screen_card_shown', {'trigger': _work?.takeoverComputer != null ? 'takeover' : 'screen_step'});
        }
        unawaited(_maybeIntro());
      }
      setState(() => _shown = next);
    } else {
      setState(() {});
    }
    _signalNeedsYou();
  }

  /// The card turned amber: one light haptic, one pulse, and the only thing a screen reader hears
  /// from it (§5, §6).
  void _signalNeedsYou() {
    final w = _work;
    final take = w?.takeoverComputer;
    if (!_shown || take == null) return;
    final key = '${w!.reply}:$take';
    if (_signalled == key) return;
    _signalled = key;
    unawaited(HapticsHelper.light());
    setState(() => _pulse++);
    unawaited(
      SemanticsService.sendAnnouncement(View.of(context), context.l10n.screenCardNeedsYou(_botName), Directionality.of(context)),
    );
  }

  /// The first time the card ever shows on this device: one line under it for four seconds.
  Future<void> _maybeIntro() async {
    if (_introChecked) return;
    _introChecked = true;
    try {
      final p = await SharedPreferences.getInstance();
      if (p.getBool(_introKey) ?? false) return;
      await p.setBool(_introKey, true);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() => _intro = true);
    _introTimer = Timer(ScreenCardTimes.intro, () {
      if (mounted) setState(() => _intro = false);
    });
  }

  Future<void> _fetch() async {
    final id = _computer;
    if (!_polling || id == null || !mounted) return;
    final pic = await ref.read(backendProvider).screenPicture(id, width: _pixelWidth, etag: _etag);
    if (!mounted || !_polling || id != _computer) return;
    switch (pic.status) {
      case ScreenPictureStatus.fresh:
        _picture = pic.bytes;
        _etag = pic.etag;
        _freshPicture();
      case ScreenPictureStatus.unchanged:
        _freshPicture();
      case ScreenPictureStatus.asleep:
      case ScreenPictureStatus.nothing:
      case ScreenPictureStatus.failed:
        // Keep the last picture; the stale timer dims it and then hides it.
        break;
    }
    _update();
    _next?.cancel();
    if (_polling) _next = Timer(ScreenCardTimes.between, () => unawaited(_fetch()));
  }

  /// The picture on screen is current: undim it and restart the stale clocks.
  void _freshPicture() {
    _stale = false;
    _pictureGone = false;
    _staleTimer?.cancel();
    _goneTimer?.cancel();
    _staleTimer = Timer(ScreenCardTimes.stale, () {
      _stale = true;
      _update();
    });
    _goneTimer = Timer(ScreenCardTimes.gone, () {
      _pictureGone = true;
      _update();
    });
  }

  /// Pixels across for the card's width on this screen (at most 480, the measured sweet spot).
  int get _pixelWidth {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2;
    final points = screenCardWidth(MediaQuery.sizeOf(context).width, widget.layout);
    return (points * dpr).round().clamp(160, 480);
  }

  ScreenTileState get _state {
    final w = _work;
    if (w?.takeoverComputer != null) return ScreenTileState.needsYou;
    if (_done) return ScreenTileState.done;
    if (w?.held ?? false) return ScreenTileState.held;
    if (_stale) return ScreenTileState.stale;
    return ScreenTileState.watching;
  }

  void _open() {
    final id = _computer;
    if (id == null) return;
    Analytics.log('screen_card_opened', {
      'state': switch (_state) {
        ScreenTileState.watching => 'watching',
        ScreenTileState.needsYou => 'needs_you',
        ScreenTileState.held => 'held',
        ScreenTileState.done => 'done',
        ScreenTileState.stale => 'stale',
      },
    });
    widget.onOpen(id);
    // Back from the live view, the card picks up again (didChangeDependencies won't fire).
    _back?.cancel();
    _back = Timer(const Duration(milliseconds: 400), _update);
  }

  void _close({String how = 'close'}) {
    Analytics.log('screen_card_hidden', {'how': how});
    _closedReply = _work?.reply;
    _intro = false;
    _update();
    unawaited(_countClose());
  }

  Future<void> _setCloses(int n) async {
    try {
      await (await SharedPreferences.getInstance()).setInt(_closesKey, n);
    } catch (_) {
      // Not kept: the offer may come a little later or sooner.
    }
  }

  /// Closed on three replies in a row: one toast offers to turn it off, saying where it comes back.
  Future<void> _countClose() async {
    int n;
    try {
      n = ((await SharedPreferences.getInstance()).getInt(_closesKey) ?? 0) + 1;
    } catch (_) {
      return;
    }
    await _setCloses(n >= 3 ? 0 : n);
    if (n < 3 || !mounted) return;
    final l10n = context.l10n;
    showToast(
      context,
      l10n.screenCardOfferOff,
      duration: const Duration(seconds: 8),
      action: SnackBarAction(key: const Key('screenCardTurnOff'), label: l10n.screenCardTurnOff, onPressed: () => _turnOff('setting')),
    );
  }

  void _turnOff(String how) {
    Analytics.log('screen_card_hidden', {'how': how});
    unawaited(ref.read(showScreenCardProvider.notifier).set(false));
    if (mounted) showToast(context, context.l10n.screenCardTurnedOff, replace: true);
  }

  /// Long press (§6): open, hide for this reply, or stop showing it.
  Future<void> _menu(BuildContext tile) async {
    final box = tile.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    unawaited(HapticsHelper.selection());
    final l10n = context.l10n;
    final rect = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(rect, Offset.zero & overlay.size),
      items: [
        PopupMenuItem(key: const Key('screenCardMenuOpen'), value: 'open', child: Text(l10n.screenCardOpen)),
        PopupMenuItem(key: const Key('screenCardMenuHide'), value: 'hide', child: Text(l10n.screenCardHideForNow)),
        PopupMenuItem(key: const Key('screenCardMenuOff'), value: 'off', child: Text(l10n.screenCardDontShow)),
      ],
    );
    if (!mounted) return;
    switch (picked) {
      case 'open':
        _open();
      case 'hide':
        _close(how: 'menu');
      case 'off':
        _turnOff('menu');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Covered or uncovered by another page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ready = true;
      _update();
    });
  }

  @override
  Widget build(BuildContext context) {
    final picture = _picture;
    final corner = ref.watch(screenCardCornerProvider);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final bot = _work?.bot;
    final face = widget.faceFor != null && bot != null ? widget.faceFor!(bot) : null;
    return LayoutBuilder(
      builder: (context, box) {
        final width = screenCardWidth(box.maxWidth, widget.layout);
        return ScreenTileCorner(
          width: width,
          caption: _intro && _shown ? _Intro(text: context.l10n.screenCardIntro(_botName), right: corner.x > 0) : null,
          // It grows out of its corner, toward the header (§3). With Reduce Motion on, it only fades.
          child: AnimatedSlide(
            offset: _shown || reduce ? Offset.zero : Offset(0, corner.y < 0 ? -0.15 : 0.15),
            duration: AppMotion.of(context, AppMotion.duration),
            curve: AppMotion.curve,
            child: AnimatedScale(
              scale: _shown || reduce ? 1 : 0.2,
              alignment: Alignment(corner.x, corner.y),
              duration: AppMotion.of(context, AppMotion.duration),
              curve: AppMotion.curve,
              child: AnimatedOpacity(
                opacity: _shown ? 1 : 0,
                duration: AppMotion.fast,
                child: IgnorePointer(
                  ignoring: !_shown,
                  child: ExcludeSemantics(
                    excluding: !_shown,
                    // One pulse when it turns amber.
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(_pulse),
                      tween: Tween(begin: _pulse == 0 || reduce ? 1 : 1.08, end: 1),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                      child: Builder(
                        builder: (tile) => ScreenTile(
                          key: const Key('screenCard'),
                          picture: picture == null
                              ? null
                              : Image.memory(picture, fit: BoxFit.cover, alignment: Alignment.topCenter, gaplessPlayback: true),
                          state: _state,
                          botName: _botName,
                          face: face,
                          onTap: _open,
                          onClose: _close,
                          onLongPress: () => unawaited(_menu(tile)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// "Ava's screen. Tap to watch, drag to move." beside the card the first time (§3).
class _Intro extends StatelessWidget {
  const _Intro({required this.text, required this.right});
  final String text;
  final bool right;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      child: DecoratedBox(
        key: const Key('screenCardIntro'),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(text, style: context.textTheme.labelSmall?.copyWith(color: Colors.white)),
        ),
      ),
    );
  }
}

/// The sample card over a chat's thread. A tap moves to the next state, as does each 4 seconds;
/// the close button hides it for 5 seconds.
class ScreenCardPreview extends StatefulWidget {
  const ScreenCardPreview({super.key, required this.botName, required this.layout});
  final String botName;
  final LayoutSize layout;

  @override
  State<ScreenCardPreview> createState() => _ScreenCardPreviewState();
}

class _ScreenCardPreviewState extends State<ScreenCardPreview> {
  static const _order = [
    ScreenTileState.watching,
    ScreenTileState.needsYou,
    ScreenTileState.held,
    ScreenTileState.stale,
    ScreenTileState.done,
  ];
  var _i = 0;
  var _shown = true;
  Timer? _cycle;
  Timer? _back;

  @override
  void initState() {
    super.initState();
    _startCycle();
  }

  void _startCycle() {
    _cycle?.cancel();
    _cycle = Timer.periodic(const Duration(seconds: 4), (_) => _next());
  }

  void _next() {
    if (mounted) setState(() => _i = (_i + 1) % _order.length);
  }

  void _close() {
    setState(() => _shown = false);
    _back?.cancel();
    _back = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  void dispose() {
    _cycle?.cancel();
    _back?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = screenCardWidth(box.maxWidth, widget.layout);
        final state = _order[_i];
        return ScreenTileCorner(
          width: width,
          insets: const EdgeInsets.all(AppSpace.sm),
          // It grows from the header's monitor button (top right) and folds back into it.
          child: AnimatedScale(
            scale: _shown ? 1 : 0.2,
            alignment: Alignment.topRight,
            duration: AppMotion.of(context, AppMotion.duration),
            curve: AppMotion.curve,
            child: AnimatedOpacity(
              opacity: _shown ? 1 : 0,
              duration: AppMotion.of(context, AppMotion.fast),
              child: IgnorePointer(
                ignoring: !_shown,
                child: ScreenTile(
                  picture: _SampleScreen(frozen: state != ScreenTileState.watching && state != ScreenTileState.needsYou),
                  state: state,
                  botName: widget.botName,
                  onTap: () {
                    _next();
                    _startCycle();
                  },
                  onClose: _close,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A made-up web page with a pointer that moves once a second, as real pictures would.
class _SampleScreen extends StatefulWidget {
  const _SampleScreen({required this.frozen});
  final bool frozen;

  @override
  State<_SampleScreen> createState() => _SampleScreenState();
}

class _SampleScreenState extends State<_SampleScreen> {
  static const _spots = [Offset(0.22, 0.5), Offset(0.5, 0.5), Offset(0.78, 0.5), Offset(0.5, 0.86), Offset(0.62, 0.1)];
  var _frame = 0;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !widget.frozen) setState(() => _frame++);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spot = _spots[_frame % _spots.length];
    final picked = _frame % _spots.length;
    return ColoredBox(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth, h = box.maxHeight;
          Widget bar(double width, {Color color = const Color(0xFFD7DAE0), double height = 4}) => Container(
            width: width,
            height: height,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          );
          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: h * 0.13,
                    color: const Color(0xFFEEF0F3),
                    padding: EdgeInsets.symmetric(horizontal: w * 0.18, vertical: h * 0.035),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(w * 0.06, h * 0.06, w * 0.06, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bar(w * 0.5, color: const Color(0xFF2F5BEA), height: h * 0.07),
                        SizedBox(height: h * 0.05),
                        Row(
                          children: [
                            for (var k = 0; k < 3; k++) ...[
                              if (k > 0) SizedBox(width: w * 0.03),
                              Container(
                                width: w * 0.26,
                                height: h * 0.26,
                                decoration: BoxDecoration(
                                  color: k == picked ? const Color(0xFFDDE6FF) : const Color(0xFFF1F3F6),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: h * 0.06),
                        bar(w * 0.8),
                        SizedBox(height: h * 0.03),
                        bar(w * 0.55),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                left: spot.dx * w - 4,
                top: spot.dy * h - 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

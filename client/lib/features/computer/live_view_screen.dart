import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart' show XFile;

import '../../core/live.dart';
import '../../core/providers.dart';
import '../../core/share.dart';
import '../../core/user_activity.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/shell_header.dart';
import '../../ui/glow_button.dart';
import '../teach/teach_draft_screen.dart';
import '../teach/teach_recorder.dart';
import '../../core/analytics.dart';
import '../../core/haptics.dart';
import '../../ui/page.dart';
import '../../ui/bot_avatar.dart';

/// Watch a computer's desktop live and take control (deep link: /computer/live?c=&takeover=).
class LiveViewScreen extends ConsumerStatefulWidget {
  const LiveViewScreen({super.key, required this.computerId, this.takeoverId, this.embedded = false, this.onExpand});
  final String computerId;
  final String? takeoverId;

  /// Inside the computer side panel on large screens: no page header, a compact bar, and a button
  /// that opens the full-screen view ([onExpand]).
  final bool embedded;
  final VoidCallback? onExpand;

  @override
  ConsumerState<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends ConsumerState<LiveViewScreen> with WidgetsBindingObserver {
  LiveConnection? _conn;
  Object? _error;
  Lease? _lease;
  Uint8List? _shot;
  double? _rtt;
  var _rightClick = false;
  var _busy = false;
  DateTime _lastInput = DateTime.now();
  Timer? _leaseTimer;
  Timer? _shotTimer;
  Timer? _pingTimer;
  final _transform = TransformationController();
  final _focus = FocusNode();
  // The phone keyboard types into a hidden field that always holds one invisible character, so
  // Backspace on an "empty" field still registers (and reaches the computer).
  static const _sentinel = '\u200b';
  final _typing = TextEditingController(text: _sentinel);
  final _typingFocus = FocusNode();
  var _typed = _sentinel;
  // Teach a task (D-120): a recording while we hold control.
  TeachSession? _teach;
  TeachRecorder? _recorder;
  TeachStep? _lastStep;
  var _stepQueue = Future<void>.value();
  // Activity-based keep-awake (D-195): presence while the person is here, "Still watching?" after
  // a long quiet spell, and a paused stream when nobody answers.
  late final PresenceBeat _presence;
  late final RecentInput _idle;
  var _stillWatching = false;
  var _powerPaused = false;
  Timer? _answerTimer;
  Timer? _idleRecheck;
  var _privacyNote = false;
  Timer? _privacyTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _presence = PresenceBeat(() => _conn?.presence());
    _idle = RecentInput(KeepAwake.stillWatchingAfter, onQuiet: _checkStillWatching, onActive: _keepWatching);
    _connect();
    _refreshLease();
    _leaseTimer = Timer.periodic(const Duration(seconds: 5), (_) => _tickLease());
  }

  var _disposed = false;

  /// setState that is safe while the connection is closing during dispose.
  void _refresh() {
    if (!_disposed && mounted) setState(() {});
  }

  void _refreshWith(VoidCallback change) {
    if (!_disposed && mounted) setState(change);
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _leaseTimer?.cancel();
    _shotTimer?.cancel();
    _pingTimer?.cancel();
    _answerTimer?.cancel();
    _idleRecheck?.cancel();
    _privacyTimer?.cancel();
    _presence.dispose();
    _idle.dispose();
    unawaited(_conn?.close());
    _transform.dispose();
    _focus.dispose();
    _typing.dispose();
    _typingFocus.dispose();
    _recorder?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No video while nobody can see it (app in the background, a hidden browser tab, a minimised
    // window); reconnect when it's back, unless it was paused to save power.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _closeStream();
    } else if (state == AppLifecycleState.resumed && _conn == null && !_powerPaused) {
      _connect();
    }
  }

  /// Closes the stream and stops everything that would keep the computer awake for it.
  void _closeStream() {
    unawaited(_conn?.close());
    _conn = null;
    _shotTimer?.cancel();
    _shotTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _refresh();
  }

  // --- still watching? (D-195) ---------------------------------------------

  /// After [KeepAwake.stillWatchingAfter] without input: asks, unless a bot is working here.
  Future<void> _checkStillWatching() async {
    _idleRecheck?.cancel();
    if (_disposed || _idle.active || _stillWatching || _powerPaused || _conn == null) return;
    if (await _botWorking()) {
      _idleRecheck = Timer(const Duration(minutes: 1), _checkStillWatching);
      return;
    }
    if (_disposed || !mounted || _idle.active || _conn == null) return;
    setState(() => _stillWatching = true);
    _answerTimer?.cancel();
    _answerTimer = Timer(KeepAwake.answerWindow, _pauseToSavePower);
  }

  /// Whether a bot is working on this computer now (fresh bot statuses; false when unknown).
  Future<bool> _botWorking() async {
    try {
      final org = ref.read(currentOrgProvider);
      if (org == null) return false;
      final computer = (ref.read(computersProvider).value ?? const <Computer>[]).where((c) => c.id == widget.computerId).firstOrNull;
      final bots = await ref.read(backendProvider).bots(org.id);
      return bots.any(
        (b) =>
            b.status == BotStatusEnum.working &&
            (b.defaultComputerId == widget.computerId || computer?.ownerBotId == b.id || (b.defaultComputerId == null && computer?.kind != ComputerKindEnum.private)),
      );
    } catch (_) {
      return false;
    }
  }

  /// Any input (including the Keep watching button) answers the question.
  void _keepWatching() {
    _answerTimer?.cancel();
    _idleRecheck?.cancel();
    if (_stillWatching && !_disposed && mounted) setState(() => _stillWatching = false);
  }

  void _pauseToSavePower() {
    if (_disposed || !mounted) return;
    _closeStream();
    setState(() {
      _stillWatching = false;
      _powerPaused = true;
    });
  }

  /// Resume after a pause to save power: reconnecting wakes the computer.
  void _resume() {
    setState(() => _powerPaused = false);
    _connect();
  }

  Future<void> _connect() async {
    setState(() => _error = null);
    try {
      final backend = ref.read(backendProvider);
      final session = await backend.streamSession(widget.computerId, mode: 'control');
      final conn = await ref.read(liveConnectorProvider).connect(session);
      if (!mounted) {
        await conn.close();
        return;
      }
      conn.state.addListener(_onState);
      conn.isHost.addListener(_refresh);
      conn.screenSize.addListener(_refresh);
      setState(() => _conn = conn);
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        final rtt = await _conn?.ping();
        if (mounted && rtt != null) setState(() => _rtt = rtt);
      });
      // If we already hold the lease (for example after a reconnect), take control again.
      if (_lease?.you == true) conn.requestControl();
    } catch (e) {
      if (mounted) setState(() => _error = e);
      _startFallback();
    }
  }

  var _fallbackLogged = false;

  void _onState() {
    if (_disposed || !mounted) return;
    if (_conn?.state.value == LiveState.fallback) {
      if (!_fallbackLogged) Analytics.log('live_view_failed', {'fallback': 'screenshot'});
      _fallbackLogged = true;
      _startFallback();
    }
    setState(() {});
  }

  /// Networks that block WebRTC still see the screen: one screenshot a second.
  void _startFallback() {
    _shotTimer ??= Timer.periodic(const Duration(seconds: 1), (_) async {
      final png = await ref.read(backendProvider).screenshot(widget.computerId);
      if (mounted && png != null) setState(() => _shot = png.isEmpty ? null : png);
    });
  }

  Future<void> _refreshLease() async {
    try {
      final l = await ref.read(backendProvider).lease(widget.computerId);
      if (mounted) setState(() => _lease = l);
    } catch (_) {}
  }

  /// Renews our lease while we are giving input; 15 minutes without input lets it lapse.
  Future<void> _tickLease() async {
    if (_lease?.you == true && DateTime.now().difference(_lastInput) < const Duration(minutes: 14)) {
      try {
        final l = await ref.read(backendProvider).takeLease(widget.computerId);
        if (mounted) setState(() => _lease = l);
        return;
      } catch (_) {}
    }
    await _refreshLease();
  }

  Future<void> _takeControl() async {
    setState(() => _busy = true);
    final l = await runGuarded(context, () => ref.read(backendProvider).takeLease(widget.computerId));
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (l != null) _lease = l;
    });
    if (l != null) {
      _lastInput = DateTime.now();
      _conn?.requestControl();
      _focus.requestFocus();
      // Said once, as control starts, over the top of the screen: it doesn't stay, and it doesn't
      // cover the tools the person is about to use.
      setState(() => _privacyNote = true);
      _privacyTimer?.cancel();
      _privacyTimer = Timer(const Duration(seconds: 6), () => _refreshWith(() => _privacyNote = false));
    }
  }

  Future<void> _handBack() async {
    final text = await showAdaptiveSheet<String>(context: context, builder: (_) => const _HandBackDialog());
    if (text == null || !mounted) return;
    if (_teach != null) await _stopTeach();
    if (!mounted) return;
    _conn?.releaseControl();
    final l = await runGuarded(context, () => ref.read(backendProvider).releaseLease(widget.computerId, note: text.isEmpty ? null : text));
    if (mounted && l != null) setState(() => _lease = l);
  }

  bool get _controlling => _lease?.you == true && (_conn?.isHost.value ?? false);

  // --- quick actions -------------------------------------------------------

  void _keyCombo(int modifier, int key) {
    _send(NekoInput.key(modifier, down: true));
    _send(NekoInput.key(key, down: true));
    _send(NekoInput.key(key, down: false));
    _send(NekoInput.key(modifier, down: false));
  }

  /// This device's clipboard onto the computer's, then Ctrl+V there.
  Future<void> _paste() async {
    final conn = _conn;
    if (conn == null || !_controlling) return;
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    if (!mounted) return;
    if (text.isEmpty) return showWarning(context, context.l10n.livePasteEmpty);
    conn.setClipboard(text);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _keyCombo(0xffe3, 0x76);
  }

  /// Ctrl+C on the computer, then what it copied onto this device's clipboard.
  Future<void> _copy() async {
    final conn = _conn;
    if (conn == null || !_controlling) return;
    final before = conn.remoteClipboard.value;
    final done = Completer<String?>();
    void changed() {
      if (!done.isCompleted && conn.remoteClipboard.value != before) done.complete(conn.remoteClipboard.value);
    }

    conn.remoteClipboard.addListener(changed);
    _keyCombo(0xffe3, 0x63);
    final text = await done.future.timeout(const Duration(milliseconds: 1500), onTimeout: () => null);
    conn.remoteClipboard.removeListener(changed);
    if (!mounted) return;
    if (text == null || text.isEmpty) return showWarning(context, context.l10n.liveNothingCopied);
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) showMessage(context, context.l10n.liveCopied);
  }

  /// A screenshot of the computer, saved or shared from this device.
  Future<void> _screenshot(BuildContext button) async {
    final origin = shareOrigin(button);
    final fetched = await runGuarded(context, () => ref.read(backendProvider).screenshot(widget.computerId));
    final png = (fetched == null || fetched.isEmpty) ? _shot : fetched;
    if (png == null || !mounted) return;
    final name = 'computer-${DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-')}.png';
    await shareFiles([XFile.fromData(png, name: name, mimeType: 'image/png')], names: [name], origin: origin);
  }

  // --- teach a task (D-120) -------------------------------------------------

  Future<void> _startTeach() async {
    final l10n = context.l10n;
    final computers = await ref.read(computersProvider.future).catchError((Object _) => const <Computer>[]);
    if (!mounted) return;
    var botId = computers.where((c) => c.id == widget.computerId).firstOrNull?.ownerBotId;
    if (botId == null) {
      final bots = await ref.read(botsProvider.future).catchError((Object _) => const <Bot>[]);
      if (!mounted) return;
      botId = (await showChoiceSheet<String>(
        context,
        icon: LucideIcons.graduationCap,
        title: l10n.teachWhichBot,
        choices: [
          for (final b in bots)
            Choice(key: Key('teachBot-${b.id}'), value: b.id, label: b.name, leading: BotAvatar(name: b.name, avatar: b.avatarUrl, size: 32, animate: false)),
        ],
      ))?.value;
      if (botId == null || !mounted) return;
    }
    final s = await runGuarded(context, () => ref.read(backendProvider).startTeach(widget.computerId, botId!));
    if (s == null || !mounted) return;
    setState(() {
      _teach = s;
      _lastStep = null;
      _recorder = TeachRecorder(_sendStep);
    });
  }

  /// Steps go one at a time, in order; losing control ends the recording.
  void _sendStep(AddTeachStepRequest step) {
    final s = _teach;
    if (s == null) return;
    _stepQueue = _stepQueue.then((_) async {
      try {
        final st = await ref.read(backendProvider).addTeachStep(s.id, step);
        if (mounted && _teach?.id == s.id) setState(() => _lastStep = st);
      } catch (e) {
        if (!mounted || _teach?.id != s.id) return;
        showError(context, e);
        setState(() {
          _recorder?.dispose();
          _recorder = null;
        });
      }
    });
  }

  Future<void> _stopTeach() async {
    final s = _teach;
    if (s == null) return;
    _recorder?.flush();
    await _stepQueue;
    if (!mounted) return;
    setState(() {
      _recorder?.dispose();
      _recorder = null;
      _teach = null;
      _lastStep = null;
    });
    final stopped = await runGuarded(context, () => ref.read(backendProvider).stopTeach(s.id));
    if (stopped != null && mounted) unawaited(GoRouter.maybeOf(context)?.push('/teach/${s.id}'));
  }

  Future<void> _markSecret(TeachStep st) async {
    final s = _teach;
    if (s == null) return;
    final name = await showAdaptiveSheet<String>(context: context, builder: (_) => const _SecretNameSheet());
    if (name == null || !mounted) return;
    final updated = await runGuarded(context, () => ref.read(backendProvider).markTeachSecret(s.id, st.seq, name));
    if (updated != null && mounted) setState(() => _lastStep = updated);
  }

  /// A Flutter key as a readable name for the recording.
  static String? _keyName(KeyEvent e) {
    final k = e.logicalKey;
    if ({LogicalKeyboardKey.shift, LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftRight, LogicalKeyboardKey.control, LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.controlRight, LogicalKeyboardKey.alt, LogicalKeyboardKey.altLeft, LogicalKeyboardKey.altRight, LogicalKeyboardKey.meta, LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.metaRight}.contains(k)) return null;
    final mods = [
      if (HardwareKeyboard.instance.isControlPressed) 'Ctrl',
      if (HardwareKeyboard.instance.isMetaPressed) 'Cmd',
      if (HardwareKeyboard.instance.isAltPressed) 'Alt',
    ];
    final label = k.keyLabel.isEmpty ? k.debugName ?? '?' : k.keyLabel;
    return [...mods, label].join('+');
  }

  void _recordKey(KeyEvent e) {
    final r = _recorder;
    if (r == null || e is KeyUpEvent) return;
    final ch = e.character;
    final plain = !HardwareKeyboard.instance.isControlPressed && !HardwareKeyboard.instance.isMetaPressed;
    if (plain && ch != null && ch.isNotEmpty && ch.runes.every((c) => c >= 0x20 && c != 0x7f)) {
      r.char(ch);
    } else if (e.logicalKey == LogicalKeyboardKey.backspace) {
      r.backspace();
    } else {
      final name = _keyName(e);
      if (name != null) r.key(name);
    }
  }

  // --- input ---------------------------------------------------------------

  Offset? _toRemote(Offset local, Size box) {
    final size = _conn?.screenSize.value;
    if (size == null || box.width == 0) return null;
    return Offset(local.dx / box.width * size.width, local.dy / box.height * size.height);
  }

  void _send(Uint8List data) {
    _lastInput = DateTime.now();
    UserActivity.instance.mark();
    _conn?.send(data);
  }

  void _pointer(PointerEvent e, Size box, {bool? down}) {
    if (!_controlling) return;
    final p = _toRemote(e.localPosition, box);
    if (p == null) return;
    _send(NekoInput.move(p.dx.round(), p.dy.round()));
    if (down == null) return;
    final button = e.kind == PointerDeviceKind.mouse
        ? (e.buttons & kSecondaryMouseButton != 0 || (!down && _lastButton == 3) ? 3 : (e.buttons & kMiddleMouseButton != 0 ? 2 : 1))
        : (_rightClick ? 3 : 1);
    if (down) _lastButton = button;
    _send(NekoInput.button(down ? button : _lastButton, down: down));
    if (!down) _recorder?.click(p.dx.round(), p.dy.round(), button: _lastButton);
    if (!down && _rightClick) setState(() => _rightClick = false);
  }

  int _lastButton = 1;

  KeyEventResult _key(FocusNode _, KeyEvent e) {
    if (!_controlling) return KeyEventResult.ignored;
    final sym = keysymFor(e.logicalKey, character: e.character);
    if (sym == null) return KeyEventResult.ignored;
    _send(NekoInput.key(sym, down: e is! KeyUpEvent));
    _recordKey(e);
    return KeyEventResult.handled;
  }

  /// Soft keyboard on phones: diff the hidden field and send key presses.
  void _onTyped(String value) {
    if (!_controlling) {
      _resetTyping();
      return;
    }
    if (value.length < _typed.length) {
      for (var i = 0; i < _typed.length - value.length; i++) {
        _recorder?.backspace();
        _send(NekoInput.key(0xff08, down: true));
        _send(NekoInput.key(0xff08, down: false));
      }
    } else {
      for (final ch in value.substring(_typed.length).runes) {
        if (ch == 0x200b) continue;
        final sym = ch == 10 ? 0xff0d : (ch < 0x100 ? ch : 0x01000000 | ch);
        ch == 10 ? _recorder?.key('Enter') : _recorder?.char(String.fromCharCode(ch));
        _send(NekoInput.key(sym, down: true));
        _send(NekoInput.key(sym, down: false));
      }
    }
    _typed = value;
    // After Return, or once the sentinel itself was deleted, start the buffer over.
    if (value.isEmpty || value.contains('\n') || value.length > 200) _resetTyping();
  }

  void _resetTyping() {
    _typed = _sentinel;
    _typing.value = const TextEditingValue(text: _sentinel, selection: TextSelection.collapsed(offset: 1));
  }

  // --- build ---------------------------------------------------------------

  /// Touch devices and phone-sized windows get the keyboard and right-click buttons; a mouse and a
  /// hardware keyboard don't need them.
  bool get _touch {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.android || AppBreakpoints.of(MediaQuery.sizeOf(context).width) == WindowSize.compact;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final conn = _conn;
    final state = conn?.state.value ?? (_error != null ? LiveState.fallback : LiveState.connecting);
    final takeovers = ref.watch(takeoversProvider).value ?? const <TakeoverRequest>[];
    TakeoverRequest? takeover;
    for (final t in takeovers) {
      if (t.id == widget.takeoverId || (widget.takeoverId == null && t.computerId == widget.computerId)) takeover = t;
    }
    final holder = _lease == null
        ? l10n.liveWatching
        : _lease!.you
        ? l10n.youAreInControl
        : (_lease!.holderType == LeaseHolderTypeEnum.user ? l10n.someoneElseInControl : l10n.botInControl);
    final media = MediaQuery.of(context);
    // A phone on its side: the computer's screen gets all of it, the controls float on top.
    final immersive = !widget.embedded && media.size.height < 500 && media.size.width > media.size.height;
    final minimize = !widget.embedded && AppBreakpoints.of(media.size.width) != WindowSize.compact && Navigator.of(context).canPop();

    final status = _StatusChip(state: state, rtt: _rtt, holder: holder, onDark: immersive);
    final more = _moreMenu(context, onDark: immersive);
    final banners = [
      if (takeover != null) _TakeoverBanner(takeover: takeover, onDismiss: () => _dismissTakeover(takeover!)),
      if (_teach != null)
        _RecordingBanner(
          lastStep: _lastStep,
          recording: _recorder != null,
          onStop: _stopTeach,
          onMarkSecret: _lastStep != null && _lastStep!.kind == TeachStepKindEnum.type && _lastStep!.secretName == null ? () => _markSecret(_lastStep!) : null,
        ),
    ];
    final canvas = _canvas(context, conn: conn, state: state, hint: !immersive && !widget.embedded && AppBreakpoints.of(media.size.width) == WindowSize.compact);
    final dock = _Dock(floating: immersive, compact: widget.embedded, children: _dockChildren(context, holder: holder));
    final typing = _typingField();

    final screen = conn?.screenSize.value ?? const Size(1280, 800);
    final rail = (media.size.width - media.size.height * screen.width / screen.height) / 2;
    if (immersive && rail >= 72) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            canvas,
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: rail,
              child: SafeArea(
                right: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                  child: Column(
                    children: [
                      _GlassButton(tooltip: MaterialLocalizations.of(context).backButtonTooltip, icon: LucideIcons.arrowLeft, onPressed: () => Navigator.of(context).maybePop()),
                      const SizedBox(height: AppSpace.xs),
                      more,
                      const Spacer(),
                      _StatusChip(state: state, rtt: _rtt, holder: holder, onDark: true, dotOnly: true),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: rail,
              child: SafeArea(
                left: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                  child: _RailColumn(children: _railChildren(context)),
                ),
              ),
            ),
            if (banners.isNotEmpty)
              Positioned(
                left: rail,
                right: rail,
                top: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.xs),
                    child: Column(children: [for (final b in banners) Padding(padding: const EdgeInsets.only(bottom: AppSpace.xs), child: b)]),
                  ),
                ),
              ),
            Positioned(left: 0, bottom: 0, child: typing),
          ],
        ),
      );
    }

    if (immersive) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            canvas,
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.xs),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _GlassButton(tooltip: MaterialLocalizations.of(context).backButtonTooltip, icon: LucideIcons.arrowLeft, onPressed: () => Navigator.of(context).maybePop()),
                        const SizedBox(width: AppSpace.xs),
                        status,
                        const Spacer(),
                        more,
                      ],
                    ),
                    for (final b in banners) Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: Padding(padding: const EdgeInsets.only(top: AppSpace.xs), child: b))),
                    const Spacer(),
                    Center(child: dock),
                  ],
                ),
              ),
            ),
            Positioned(left: 0, bottom: 0, child: typing),
          ],
        ),
      );
    }

    final gutter = widget.embedded ? AppSpace.sm : AppSpace.gutter;
    final page = Column(
      children: [
        if (widget.embedded)
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, AppSpace.xs, AppSpace.xxs, AppSpace.xs),
            child: Row(
              children: [
                status,
                const Spacer(),
                more,
                if (widget.onExpand != null)
                  IconButton(key: const Key('liveExpand'), tooltip: l10n.liveExpand, onPressed: widget.onExpand, icon: const Icon(LucideIcons.maximize2, size: 18)),
              ],
            ),
          ),
        for (final b in banners) Padding(padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpace.xs), child: b),
        Expanded(child: canvas),
        dock,
        typing,
      ],
    );
    if (widget.embedded) return Material(type: MaterialType.transparency, child: page);
    return Scaffold(
      appBar: ShellHeader(
        title: l10n.liveView,
        actions: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Center(child: status)),
          if (minimize)
            HeaderIconButton(key: const Key('liveMinimize'), tooltip: l10n.liveMinimize, icon: LucideIcons.minimize2, onPressed: () => Navigator.of(context).maybePop()),
          more,
        ],
      ),
      body: page,
    );
  }

  Future<void> _dismissTakeover(TakeoverRequest t) async {
    await runGuarded(context, () => ref.read(backendProvider).dismissTakeover(t.id));
    ref.invalidate(takeoversProvider);
  }

  /// What waits behind ⋯: things done now and then, so the dock keeps to what's used all the time.
  Widget _moreMenu(BuildContext context, {required bool onDark}) {
    final l10n = context.l10n;
    final canTeach = _lease?.you == true && _teach == null;
    return Builder(
      builder: (button) => PopupMenuButton<String>(
        key: const Key('liveMore'),
        tooltip: l10n.liveMore,
        position: PopupMenuPosition.under,
        onSelected: (v) => switch (v) {
          'screenshot' => _screenshot(button),
          'teach' => _startTeach(),
          _ => null,
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            key: const Key('liveScreenshot'),
            value: 'screenshot',
            child: ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(LucideIcons.camera, size: 20), title: Text(l10n.liveSaveScreenshot)),
          ),
          if (canTeach)
            PopupMenuItem(
              key: const Key('teachStart'),
              value: 'teach',
              child: ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(LucideIcons.graduationCap, size: 20), title: Text(l10n.teachTask)),
            ),
        ],
        child: IgnorePointer(child: onDark ? _GlassButton(tooltip: l10n.liveMore, icon: LucideIcons.ellipsis, onPressed: () {}) : HeaderIconButton(tooltip: l10n.liveMore, icon: LucideIcons.ellipsis, onPressed: () {})),
      ),
    );
  }

  /// Watching: who has the screen, and Take Control. In control: the tools a finger needs (keyboard,
  /// right-click, paste, copy) and Hand Back.
  List<Widget> _dockChildren(BuildContext context, {required String holder}) {
    final l10n = context.l10n;
    if (_lease?.you != true) {
      final someoneElse = _lease?.holderType == LeaseHolderTypeEnum.user;
      return [
        Icon(someoneElse ? LucideIcons.user : (_lease == null ? LucideIcons.eye : LucideIcons.bot), size: 18, color: context.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpace.xs),
        Expanded(
          child: Text(holder, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: AppSpace.sm),
        GlowButton.icon(
          key: const Key('takeControl'),
          onPressed: _busy || someoneElse ? null : _takeControl,
          icon: const Icon(LucideIcons.mousePointer2, size: 18),
          label: Text(l10n.takeControl),
        ),
      ];
    }
    final wide = AppBreakpoints.of(MediaQuery.sizeOf(context).width) != WindowSize.compact && !widget.embedded;
    final handBack = Tooltip(
      message: l10n.handBack,
      child: FilledButton.tonalIcon(
        key: const Key('handBack'),
        onPressed: _handBack,
        icon: const Icon(LucideIcons.undo2, size: 18),
        label: Text(l10n.handBack, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
    return [
      if (wide) const Spacer(),
      if (_touch) ...[
        _DockButton(key: const Key('liveKeyboard'), icon: LucideIcons.keyboard, tooltip: l10n.showKeyboard, onPressed: _controlling ? () => _typingFocus.requestFocus() : null),
        _DockButton(
          key: const Key('liveRightClick'),
          icon: LucideIcons.mousePointerClick,
          tooltip: l10n.rightClickNextTap,
          selected: _rightClick,
          onPressed: _controlling ? () => setState(() => _rightClick = !_rightClick) : null,
        ),
      ],
      _DockButton(key: const Key('livePaste'), icon: LucideIcons.clipboardPaste, tooltip: l10n.livePasteToComputer, onPressed: _controlling ? _paste : null),
      _DockButton(key: const Key('liveCopy'), icon: LucideIcons.copy, tooltip: l10n.liveCopyFromComputer, onPressed: _controlling ? _copy : null),
      // Wide windows keep the tools and Hand Back together in the middle; phones push Hand Back
      // to the edge, where it shrinks to its icon on the smallest screens.
      if (wide) const SizedBox(width: AppSpace.lg) else const SizedBox(width: AppSpace.xxs),
      if (wide) handBack else Expanded(child: Align(alignment: AlignmentDirectional.centerEnd, child: handBack)),
      if (wide) const Spacer(),
    ];
  }

  /// The right-hand bar on a phone held sideways: the same tools as the dock, stacked, with the
  /// main action at the bottom under the thumb.
  List<Widget> _railChildren(BuildContext context) {
    final l10n = context.l10n;
    if (_lease?.you != true) {
      final someoneElse = _lease?.holderType == LeaseHolderTypeEnum.user;
      return [
        const Spacer(),
        _RailAction(
          key: const Key('takeControl'),
          icon: LucideIcons.mousePointer2,
          label: l10n.takeControl,
          primary: true,
          onPressed: _busy || someoneElse ? null : _takeControl,
        ),
      ];
    }
    return [
      if (_touch) ...[
        _DockButton(key: const Key('liveKeyboard'), icon: LucideIcons.keyboard, tooltip: l10n.showKeyboard, onDark: true, onPressed: _controlling ? () => _typingFocus.requestFocus() : null),
        _DockButton(
          key: const Key('liveRightClick'),
          icon: LucideIcons.mousePointerClick,
          tooltip: l10n.rightClickNextTap,
          selected: _rightClick,
          onDark: true,
          onPressed: _controlling ? () => setState(() => _rightClick = !_rightClick) : null,
        ),
      ],
      _DockButton(key: const Key('livePaste'), icon: LucideIcons.clipboardPaste, tooltip: l10n.livePasteToComputer, onDark: true, onPressed: _controlling ? _paste : null),
      _DockButton(key: const Key('liveCopy'), icon: LucideIcons.copy, tooltip: l10n.liveCopyFromComputer, onDark: true, onPressed: _controlling ? _copy : null),
      const Spacer(),
      _RailAction(key: const Key('handBack'), icon: LucideIcons.undo2, label: l10n.handBack, onPressed: _handBack),
    ];
  }

  /// The computer's screen on black, pinch to zoom; touches and keys go to the computer while you
  /// have control.
  Widget _canvas(BuildContext context, {required LiveConnection? conn, required LiveState state, required bool hint}) {
    final l10n = context.l10n;
    final size = conn?.screenSize.value ?? const Size(1280, 800);
    final video = state == LiveState.fallback || conn?.renderer == null
        ? (_shot == null
              ? Center(child: Text(l10n.connectingLive, style: const TextStyle(color: Colors.white70)))
              : Image.memory(_shot!, gaplessPlayback: true, fit: BoxFit.fill))
        : RTCVideoView(conn!.renderer!, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain);
    if (_powerPaused) return _PausedToSavePower(onResume: _resume);
    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, area) {
          // Room left under the screen on a phone held upright: say it gets bigger sideways.
          final screenHeight = area.maxWidth * size.height / size.width;
          final showHint = hint && area.maxHeight - screenHeight > 160;
          return Stack(
            fit: StackFit.expand,
            children: [
              Focus(
                focusNode: _focus,
                onKeyEvent: _key,
                child: InteractiveViewer(
                  transformationController: _transform,
                  minScale: 1,
                  maxScale: 5,
                  panEnabled: !_controlling,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: size.width / size.height,
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final s = Size(box.maxWidth, box.maxHeight);
                          return Listener(
                            key: const Key('liveSurface'),
                            onPointerHover: (e) => _pointer(e, s),
                            onPointerMove: (e) => _pointer(e, s),
                            onPointerDown: (e) {
                              _focus.requestFocus();
                              _pointer(e, s, down: true);
                            },
                            onPointerUp: (e) => _pointer(e, s, down: false),
                            onPointerSignal: (e) {
                              if (e is PointerScrollEvent && _controlling) {
                                _send(NekoInput.scroll((e.scrollDelta.dx / 20).round(), (e.scrollDelta.dy / 20).round()));
                                _recorder?.scroll((e.scrollDelta.dx / 20).round(), (e.scrollDelta.dy / 20).round());
                              }
                            },
                            child: video,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpace.gutter,
                right: AppSpace.gutter,
                top: AppSpace.sm,
                child: IgnorePointer(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _privacyNote && _lease?.you == true
                          ? Container(
                              key: const Key('livePrivacy'),
                              constraints: const BoxConstraints(maxWidth: 440),
                              padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white24)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.lock, size: 16, color: Colors.white70),
                                  const SizedBox(width: AppSpace.xs),
                                  Flexible(child: Text(l10n.takeoverPrivacy, style: context.textTheme.bodySmall?.copyWith(color: Colors.white, height: 1.35))),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
              if (showHint)
                Positioned(
                  left: AppSpace.gutter,
                  right: AppSpace.gutter,
                  bottom: AppSpace.lg,
                  child: IgnorePointer(
                    child: Row(
                      key: const Key('liveRotateHint'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.smartphone, size: 16, color: Colors.white38),
                        const SizedBox(width: AppSpace.xs),
                        Flexible(child: Text(l10n.liveRotateHint, textAlign: TextAlign.center, style: context.textTheme.bodySmall?.copyWith(color: Colors.white54))),
                      ],
                    ),
                  ),
                ),
              if (_stillWatching) _StillWatching(onKeepWatching: _keepWatching),
            ],
          );
        },
      ),
    );
  }

  /// Hidden field that brings up the phone keyboard. Multi-line, so the keyboard's Enter types
  /// Return on the computer instead of closing.
  Widget _typingField() => SizedBox(
    width: 1,
    height: 1,
    child: Opacity(
      opacity: 0,
      child: TextField(
        key: const Key('liveTyping'),
        focusNode: _typingFocus,
        controller: _typing,
        onChanged: _onTyped,
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        maxLines: null,
      ),
    ),
  );
}

/// Live or Screenshots, and the round trip, in one pill. Tap it for what it means and who has the
/// screen.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.state, required this.rtt, required this.holder, this.onDark = false, this.dotOnly = false});
  final LiveState state;
  final double? rtt;
  final String holder;
  final bool onDark;

  /// Just the dot in a round button (the narrow bar beside the screen); the words are in the tip.
  final bool dotOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final dot = switch (state) {
      LiveState.live => colors.positive,
      LiveState.fallback => colors.warning,
      _ => context.colorScheme.outline,
    };
    final label = switch (state) {
      LiveState.live => l10n.live,
      LiveState.fallback => l10n.liveScreenshots,
      LiveState.closed => l10n.paused,
      LiveState.connecting => l10n.connectingLive,
    };
    final text = onDark ? Colors.white : context.colorScheme.onSurface;
    final muted = onDark ? Colors.white70 : context.colorScheme.onSurfaceVariant;
    final style = context.textTheme.labelLarge?.copyWith(color: text, fontWeight: FontWeight.w700);
    final message = [
      if (dotOnly) [label, if (rtt != null && state == LiveState.live) l10n.latencyMs(rtt!.round())].join(' · '),
      if (state == LiveState.fallback) l10n.liveScreenshotsHelp,
      holder,
    ].join('\n');
    if (dotOnly) {
      return Tooltip(
        triggerMode: TooltipTriggerMode.tap,
        showDuration: const Duration(seconds: 5),
        message: message,
        child: Container(
          key: const Key('liveStatus'),
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
          child: _Pulse(color: dot, on: state == LiveState.live),
        ),
      );
    }
    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 5),
      message: message,
      child: Container(
        key: const Key('liveStatus'),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: onDark ? Colors.black.withValues(alpha: 0.55) : context.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(17),
          border: onDark ? Border.all(color: Colors.white24) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Pulse(color: dot, on: state == LiveState.live),
            const SizedBox(width: 8),
            Text(label, style: style),
            if (rtt != null && state == LiveState.live) ...[
              Text('  ·  ', style: style?.copyWith(color: muted)),
              Text(l10n.latencyMs(rtt!.round()), key: const Key('latency'), style: style?.copyWith(color: muted, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ],
        ),
      ),
    );
  }
}

/// The status dot, with a soft halo while the video is live. Still on purpose: a looping
/// animation would redraw the page all the time it's open.
class _Pulse extends StatelessWidget {
  const _Pulse({required this.color, required this.on});
  final Color color;
  final bool on;

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: on ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6, spreadRadius: 1.5)] : null,
    ),
  );
}

/// The bar at the bottom, in reach of a thumb. On a phone held sideways it floats over the screen.
class _Dock extends StatelessWidget {
  const _Dock({required this.children, this.floating = false, this.compact = false});
  final List<Widget> children;
  final bool floating;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final row = Row(children: children);
    if (floating) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 24, offset: Offset(0, 8))],
          ),
          child: row,
        ),
      );
    }
    final gutter = compact ? AppSpace.sm : AppSpace.gutter;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kPageMaxWidth),
            child: Padding(padding: EdgeInsets.fromLTRB(gutter, 10, gutter, 10), child: row),
          ),
        ),
      ),
    );
  }
}

/// A square tool in the dock; [selected] tints it (right-click armed).
class _DockButton extends StatelessWidget {
  const _DockButton({super.key, required this.icon, required this.tooltip, required this.onPressed, this.selected = false, this.onDark = false});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;

  /// On the black bar beside the screen (phone held sideways): stacked, glassy.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Padding(
      padding: onDark ? const EdgeInsets.only(bottom: 8) : const EdgeInsetsDirectional.only(end: 4),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed == null
            ? null
            : () {
                HapticsHelper.light();
                onPressed!();
              },
        isSelected: selected,
        style: IconButton.styleFrom(
          fixedSize: const Size(44, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: selected ? scheme.primary : (onDark ? Colors.white.withValues(alpha: 0.12) : scheme.surfaceContainerHighest),
          foregroundColor: selected ? scheme.onPrimary : (onDark ? Colors.white : scheme.onSurface),
          disabledBackgroundColor: onDark ? Colors.white.withValues(alpha: 0.06) : null,
          disabledForegroundColor: onDark ? Colors.white38 : null,
        ),
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

/// The bar's tools at the top, its main action at the bottom; the tools scroll if a short screen
/// can't fit them all.
class _RailColumn extends StatelessWidget {
  const _RailColumn({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final split = children.indexWhere((w) => w is Spacer);
    final tools = split < 0 ? const <Widget>[] : children.sublist(0, split);
    final rest = split < 0 ? children : children.sublist(split + 1);
    return Column(
      children: [
        Expanded(child: SingleChildScrollView(child: Column(children: tools))),
        ...rest,
      ],
    );
  }
}

/// The main action in the bar beside the screen: a round button with its name under it.
class _RailAction extends StatelessWidget {
  const _RailAction({super.key, required this.icon, required this.label, required this.onPressed, this.primary = false});
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary ? scheme.primary : scheme.secondaryContainer,
                  boxShadow: primary ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.45), blurRadius: 18)] : null,
                ),
                child: Icon(icon, size: 22, color: primary ? scheme.onPrimary : scheme.onSecondaryContainer),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: context.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, height: 1.15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round button over the video (phone held sideways).
class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.tooltip, required this.icon, required this.onPressed});
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      fixedSize: const Size(40, 40),
      backgroundColor: Colors.black.withValues(alpha: 0.55),
      foregroundColor: Colors.white,
      side: const BorderSide(color: Colors.white24),
    ),
    icon: Icon(icon, size: 20),
  );
}

/// A bot asking the person to step in, with its reason.
class _TakeoverBanner extends StatelessWidget {
  const _TakeoverBanner({required this.takeover, required this.onDismiss});
  final TakeoverRequest takeover;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final waiting = context.appColors.waiting;
    return Container(
      key: const Key('takeoverBanner'),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: Color.alphaBlend(waiting.withValues(alpha: context.isDark ? 0.18 : 0.1), context.colorScheme.surface),
        borderRadius: BorderRadius.circular(AppRadius.row),
        border: Border.all(color: waiting.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.hand, size: 20, color: waiting),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              context.l10n.botAsksForHelp(takeover.reason),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          ),
          TextButton(onPressed: onDismiss, child: Text(context.l10n.dismiss)),
        ],
      ),
    );
  }
}

/// "Still watching?" over a dimmed view after a long quiet spell (D-195).
class _StillWatching extends StatelessWidget {
  const _StillWatching({required this.onKeepWatching});
  final VoidCallback onKeepWatching;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ColoredBox(
      key: const Key('stillWatching'),
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.gutter),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.eye, size: 28, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: AppSpace.sm),
                  Text(l10n.liveStillWatching, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpace.xs),
                  Text(l10n.liveStillWatchingHelp, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpace.md),
                  FilledButton(key: const Key('keepWatching'), onPressed: onKeepWatching, child: Text(l10n.liveKeepWatching)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The stream closed because nobody answered "Still watching?"; Resume wakes the computer again.
class _PausedToSavePower extends StatelessWidget {
  const _PausedToSavePower({required this.onResume});
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyState(
      key: const Key('livePausedToSavePower'),
      icon: LucideIcons.moon,
      title: l10n.livePausedToSavePower,
      message: l10n.livePausedToSavePowerHelp,
      action: GlowButton.icon(
        key: const Key('liveResume'),
        onPressed: onResume,
        icon: const Icon(LucideIcons.play, size: 18),
        label: Text(l10n.liveResume),
      ),
    );
  }
}

/// Asks for an optional note for the bot; returns null when cancelled.
class _HandBackDialog extends StatefulWidget {
  const _HandBackDialog();

  @override
  State<_HandBackDialog> createState() => _HandBackDialogState();
}

class _HandBackDialogState extends State<_HandBackDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.undo2,
      title: l10n.handBack,
      subtitle: l10n.handBackHelp,
      submitLabel: l10n.handBack,
      submitKey: const Key('confirmHandBack'),
      onSubmit: () => Navigator.pop(context, _note.text.trim()),
      children: [
        TextField(
          key: const Key('handBackNote'),
          controller: _note,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.handBackNote, hintText: l10n.handBackNoteHint, alignLabelWithHint: true),
          minLines: 2,
          maxLines: 4,
        ),
      ],
    );
  }
}

/// The red banner that stays on screen for the whole recording (D-120).
class _RecordingBanner extends StatelessWidget {
  const _RecordingBanner({required this.lastStep, required this.recording, required this.onStop, this.onMarkSecret});
  final TeachStep? lastStep;
  final bool recording;
  final VoidCallback onStop;
  final VoidCallback? onMarkSecret;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final red = Theme.of(context).colorScheme.error;
    return Container(
      key: const Key('teachRecording'),
      margin: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.sm),
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(color: red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.row), border: Border.all(color: red)),
      child: Row(
        children: [
          Icon(LucideIcons.circleDot, size: 18, color: red),
          const SizedBox(width: AppSpace.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recording ? l10n.teachRecording : l10n.teachRecordingPaused, style: TextStyle(color: red, fontWeight: FontWeight.w700)),
                Text(lastStep == null ? l10n.teachRecordingHelp : teachStepLabel(context, lastStep!), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (onMarkSecret != null) TextButton(key: const Key('teachMarkSecret'), onPressed: onMarkSecret, child: Text(l10n.teachMarkSecret)),
          FilledButton(key: const Key('teachStop'), style: FilledButton.styleFrom(backgroundColor: red), onPressed: onStop, child: Text(l10n.teachStop)),
        ],
      ),
    );
  }
}

/// Names a secret input: uppercase letters, digits and underscores.
class _SecretNameSheet extends StatefulWidget {
  const _SecretNameSheet();

  @override
  State<_SecretNameSheet> createState() => _SecretNameSheetState();
}

class _SecretNameSheetState extends State<_SecretNameSheet> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = _name.text.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9_]'), '_');
    final valid = RegExp(r'^[A-Z][A-Z0-9_]{0,63}$').hasMatch(name);
    return FormSheet(
      icon: LucideIcons.keyRound,
      title: l10n.teachMarkSecret,
      subtitle: l10n.teachMarkSecretHelp,
      submitLabel: l10n.save,
      submitKey: const Key('teachSecretSave'),
      onSubmit: valid ? () => Navigator.pop(context, name) : null,
      children: [
        TextField(key: const Key('teachSecretName'), controller: _name, autofocus: true, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: l10n.secretName, hintText: 'EMPLOYEE_ID')),
      ],
    );
  }
}

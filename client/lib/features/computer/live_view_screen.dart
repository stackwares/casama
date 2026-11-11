import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/edge_fade.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/shell_header.dart';
import '../../ui/glow_button.dart';
import '../teach/teach_draft_screen.dart';
import '../teach/teach_recorder.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connect();
    _refreshLease();
    _leaseTimer = Timer.periodic(const Duration(seconds: 5), (_) => _tickLease());
  }

  var _disposed = false;

  /// setState that is safe while the connection is closing during dispose.
  void _refresh() {
    if (!_disposed && mounted) setState(() {});
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _leaseTimer?.cancel();
    _shotTimer?.cancel();
    _pingTimer?.cancel();
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
    // No video while the app is in the background; reconnect when it returns.
    if (state == AppLifecycleState.paused) {
      unawaited(_conn?.close());
      _conn = null;
      _shotTimer?.cancel();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && _conn == null) {
      _connect();
    }
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

  void _onState() {
    if (_disposed || !mounted) return;
    if (_conn?.state.value == LiveState.fallback) _startFallback();
    setState(() {});
  }

  /// Networks that block WebRTC still see the screen: one screenshot a second.
  void _startFallback() {
    _shotTimer ??= Timer.periodic(const Duration(seconds: 1), (_) async {
      final png = await ref.read(backendProvider).screenshot(widget.computerId);
      if (mounted && png != null) setState(() => _shot = png);
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
    final png = await runGuarded(context, () => ref.read(backendProvider).screenshot(widget.computerId)) ?? _shot;
    if (png == null || !mounted) return;
    final name = 'computer-${DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-')}.png';
    await shareFiles([XFile.fromData(png, name: name, mimeType: 'image/png')], names: [name], origin: origin);
  }

  Widget _quickActions(BuildContext context, double gutter) {
    final l10n = context.l10n;
    final phone = AppBreakpoints.of(MediaQuery.sizeOf(context).width) == WindowSize.compact;
    Widget action(Key key, IconData icon, String label, VoidCallback? onPressed) => TextButton.icon(
      key: key,
      style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 10)),
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
    return EdgeFade(child: SingleChildScrollView(
      key: const Key('liveQuickActions'),
      scrollDirection: Axis.horizontal,
      // Scrolls to the screen edges and carries its own gutter (- 6 lines the first button's icon up with the text above).
      padding: EdgeInsets.fromLTRB(gutter - 6, 0, gutter, 0),
      child: Row(
        children: [
          action(const Key('liveCopy'), LucideIcons.copy, l10n.liveCopy, _controlling ? _copy : null),
          action(const Key('livePaste'), LucideIcons.clipboardPaste, l10n.pasteLabel, _controlling ? _paste : null),
          Builder(builder: (b) => action(const Key('liveScreenshot'), LucideIcons.camera, l10n.liveScreenshot, () => _screenshot(b))),
          if (phone && _controlling) action(const Key('liveKeyboard'), LucideIcons.keyboard, l10n.showKeyboard, () => _typingFocus.requestFocus()),
        ],
      ),
    ));
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
      botId = await showAdaptiveSheet<String>(
        context: context,
        builder: (c) => FormSheet(
          icon: LucideIcons.graduationCap,
          title: l10n.teachWhichBot,
          submitLabel: l10n.cancel,
          onSubmit: () => Navigator.pop(c),
          children: [for (final b in bots) ListTile(key: Key('teachBot-${b.id}'), title: Text(b.name), onTap: () => Navigator.pop(c, b.id))],
        ),
      );
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
        ? ''
        : _lease!.you
        ? l10n.youAreInControl
        : (_lease!.holderType == LeaseHolderTypeEnum.user ? l10n.someoneElseInControl : l10n.botInControl);
    final size = conn?.screenSize.value ?? const Size(1280, 800);

    final video = state == LiveState.fallback || conn?.renderer == null
        ? (_shot == null
              ? Center(
                  child: Text(l10n.connectingLive, style: const TextStyle(color: Colors.white70)),
                )
              : Image.memory(_shot!, gaplessPlayback: true, fit: BoxFit.fill))
        : RTCVideoView(conn!.renderer!, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain);

    final minimize = !widget.embedded && AppBreakpoints.of(MediaQuery.sizeOf(context).width) != WindowSize.compact && Navigator.of(context).canPop();
    final page = Column(
      children: _body(context, state: state, takeover: takeover, holder: holder, size: size, video: video),
    );
    if (widget.embedded) return Material(type: MaterialType.transparency, child: page);
    return Scaffold(
      appBar: ShellHeader(
        title: l10n.liveView,
        actions: [
          if (minimize)
            HeaderIconButton(key: const Key('liveMinimize'), tooltip: l10n.liveMinimize, icon: LucideIcons.minimize2, onPressed: () => Navigator.of(context).maybePop()),
          if (_rtt != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Center(
                child: StatusLabel(
                  key: const Key('latency'),
                  text: l10n.latencyMs(_rtt!.round()),
                  color: _rtt! < 120 ? context.appColors.positive : context.appColors.warning,
                  pill: true,
                  icon: LucideIcons.activity,
                ),
              ),
            ),
          if (_controlling) ...[
            HeaderIconButton(
              tooltip: l10n.rightClickNextTap,
              selected: _rightClick,
              icon: LucideIcons.mousePointer2,
              onPressed: () => setState(() => _rightClick = !_rightClick),
            ),
            HeaderIconButton(tooltip: l10n.showKeyboard, icon: LucideIcons.keyboard, onPressed: () => _typingFocus.requestFocus()),
          ],
          if (_lease?.you == true && _teach == null)
            HeaderIconButton(key: const Key('teachStart'), tooltip: l10n.teachTask, icon: LucideIcons.graduationCap, onPressed: _startTeach),
        ],
      ),
      body: page,
    );
  }

  List<Widget> _body(
    BuildContext context, {
    required LiveState state,
    required TakeoverRequest? takeover,
    required String holder,
    required Size size,
    required Widget video,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final gutter = widget.embedded ? AppSpace.sm : AppSpace.gutter;
    return [
          if (takeover != null)
            Container(
              key: const Key('takeoverBanner'),
              margin: EdgeInsets.fromLTRB(gutter, AppSpace.xs, gutter, 0),
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
              decoration: BoxDecoration(
                color: context.appColors.waiting.withValues(alpha: context.isDark ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(AppRadius.row),
                border: Border.all(color: context.appColors.waiting.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.hand, size: 20, color: context.appColors.waiting),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(child: Text(l10n.botAsksForHelp(takeover.reason), style: theme.textTheme.bodyMedium?.copyWith(height: 1.35))),
                  TextButton(
                    onPressed: () async {
                      await runGuarded(context, () => ref.read(backendProvider).dismissTakeover(takeover.id));
                      ref.invalidate(takeoversProvider);
                    },
                    child: Text(l10n.dismiss),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, AppSpace.sm, gutter, AppSpace.sm),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: switch (state) {
                      LiveState.live => context.appColors.positive,
                      LiveState.fallback => context.appColors.warning,
                      _ => theme.colorScheme.outline,
                    },
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(
                    [
                      switch (state) {
                        LiveState.live => l10n.live,
                        LiveState.fallback => l10n.screenshotMode,
                        LiveState.closed => l10n.paused,
                        LiveState.connecting => l10n.connectingLive,
                      },
                      if (holder.isNotEmpty) holder,
                    ].join(' · '),
                    key: const Key('liveStatus'),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (_lease?.you == true)
                  FilledButton.tonalIcon(
                    key: const Key('handBack'),
                    onPressed: _handBack,
                    icon: const Icon(LucideIcons.undo2, size: 18),
                    label: Text(l10n.handBack),
                  )
                else
                  GlowButton.icon(
                    key: const Key('takeControl'),
                    onPressed: _busy || (_lease?.holderType == LeaseHolderTypeEnum.user) ? null : _takeControl,
                    icon: const Icon(LucideIcons.mousePointer2, size: 18),
                    label: Text(l10n.takeControl),
                  ),
                if (widget.embedded && widget.onExpand != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    key: const Key('liveExpand'),
                    tooltip: l10n.liveExpand,
                    onPressed: widget.onExpand,
                    icon: const Icon(LucideIcons.maximize2, size: 18),
                  ),
                ],
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.only(bottom: AppSpace.xs), child: _quickActions(context, gutter)),
          if (_teach != null)
            _RecordingBanner(
              lastStep: _lastStep,
              recording: _recorder != null,
              onStop: _stopTeach,
              onMarkSecret: _lastStep != null && _lastStep!.kind == TeachStepKindEnum.type && _lastStep!.secretName == null ? () => _markSecret(_lastStep!) : null,
            )
          else if (_lease?.you == true)
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpace.sm),
              child: FormNote(l10n.takeoverPrivacy, icon: LucideIcons.lock),
            ),
          Expanded(
            child: Container(
              color: Colors.black,
              child: Focus(
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
            ),
          ),
          // Hidden field that brings up the phone keyboard.
          SizedBox(
            height: 1,
            child: Opacity(
              opacity: 0,
              // Multi-line, so the keyboard's Enter types Return on the computer instead of closing.
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
          ),
    ];
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

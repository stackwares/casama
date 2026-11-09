import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/live.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../ui/shell_header.dart';

/// Watch a computer's desktop live and take control (deep link: /computer/live?c=&takeover=).
class LiveViewScreen extends ConsumerStatefulWidget {
  const LiveViewScreen({super.key, required this.computerId, this.takeoverId});
  final String computerId;
  final String? takeoverId;

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
  final _typing = TextEditingController();
  final _typingFocus = FocusNode();
  var _typed = '';

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
    final text = await showDialog<String>(context: context, builder: (_) => const _HandBackDialog());
    if (text == null || !mounted) return;
    _conn?.releaseControl();
    final l = await runGuarded(
      context,
      () => ref.read(backendProvider).releaseLease(widget.computerId, note: text.isEmpty ? null : text),
    );
    if (mounted && l != null) setState(() => _lease = l);
  }

  bool get _controlling => _lease?.you == true && (_conn?.isHost.value ?? false);

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
    if (!down && _rightClick) setState(() => _rightClick = false);
  }

  int _lastButton = 1;

  KeyEventResult _key(FocusNode _, KeyEvent e) {
    if (!_controlling) return KeyEventResult.ignored;
    final sym = keysymFor(e.logicalKey, character: e.character);
    if (sym == null) return KeyEventResult.ignored;
    _send(NekoInput.key(sym, down: e is! KeyUpEvent));
    return KeyEventResult.handled;
  }

  /// Soft keyboard on phones: diff the hidden field and send key presses.
  void _onTyped(String value) {
    if (!_controlling) return;
    if (value.length < _typed.length) {
      for (var i = 0; i < _typed.length - value.length; i++) {
        _send(NekoInput.key(0xff08, down: true));
        _send(NekoInput.key(0xff08, down: false));
      }
    } else {
      for (final ch in value.substring(_typed.length).runes) {
        final sym = ch == 10 ? 0xff0d : (ch < 0x100 ? ch : 0x01000000 | ch);
        _send(NekoInput.key(sym, down: true));
        _send(NekoInput.key(sym, down: false));
      }
    }
    _typed = value;
  }

  // --- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
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
            ? Center(child: Text(l10n.connectingLive, style: const TextStyle(color: Colors.white70)))
            : Image.memory(_shot!, gaplessPlayback: true, fit: BoxFit.fill))
        : RTCVideoView(conn!.renderer!, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain);

    return Scaffold(
      appBar: ShellHeader(
        title: l10n.liveView,
        actions: [
          if (_rtt != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: Text(l10n.latencyMs(_rtt!.round()), key: const Key('latency'), style: theme.textTheme.labelMedium)),
            ),
          if (_controlling) ...[
            IconButton(
              tooltip: l10n.rightClickNextTap,
              isSelected: _rightClick,
              icon: const Icon(Icons.mouse_outlined),
              onPressed: () => setState(() => _rightClick = !_rightClick),
            ),
            IconButton(
              tooltip: l10n.showKeyboard,
              icon: const Icon(Icons.keyboard_outlined),
              onPressed: () => _typingFocus.requestFocus(),
            ),
          ],
        ],
      ),
      body: Column(children: [
        if (takeover != null)
          MaterialBanner(
            key: const Key('takeoverBanner'),
            leading: const Icon(Icons.front_hand_outlined),
            content: Text(l10n.botAsksForHelp(takeover.reason)),
            actions: [
              TextButton(
                onPressed: () async {
                  await runGuarded(context, () => ref.read(backendProvider).dismissTakeover(takeover!.id));
                  ref.invalidate(takeoversProvider);
                },
                child: Text(l10n.dismiss),
              ),
            ],
          ),
        Container(
          width: double.infinity,
          color: theme.colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(children: [
            Icon(
              state == LiveState.live ? Icons.circle : Icons.circle_outlined,
              size: 10,
              color: state == LiveState.live ? Colors.green : theme.colorScheme.outline,
            ),
            const SizedBox(width: 8),
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
              ),
            ),
            if (_lease?.you == true)
              FilledButton.tonal(key: const Key('handBack'), onPressed: _handBack, child: Text(l10n.handBack))
            else
              FilledButton(
                key: const Key('takeControl'),
                onPressed: _busy || (_lease?.holderType == LeaseHolderTypeEnum.user) ? null : _takeControl,
                child: Text(l10n.takeControl),
              ),
          ]),
        ),
        if (_lease?.you == true)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Text(l10n.takeoverPrivacy, style: theme.textTheme.bodySmall),
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
            child: TextField(focusNode: _typingFocus, controller: _typing, onChanged: _onTyped, autocorrect: false, enableSuggestions: false),
          ),
        ),
      ]),
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
    return AlertDialog(
      title: Text(l10n.handBack),
      content: TextField(
        key: const Key('handBackNote'),
        controller: _note,
        decoration: InputDecoration(labelText: l10n.handBackNote, hintText: l10n.handBackNoteHint),
        maxLines: 3,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          key: const Key('confirmHandBack'),
          onPressed: () => Navigator.pop(context, _note.text.trim()),
          child: Text(l10n.handBack),
        ),
      ],
    );
  }
}

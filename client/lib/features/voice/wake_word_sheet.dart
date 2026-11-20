import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../ui/form_sheet.dart';
import 'wake_word.dart';

/// Settings → Wake word (D-144): this device listens for a phrase and opens a live call.
class WakeWordSheet extends ConsumerStatefulWidget {
  const WakeWordSheet({super.key});
  @override
  ConsumerState<WakeWordSheet> createState() => _WakeWordSheetState();
}

class _WakeWordSheetState extends ConsumerState<WakeWordSheet> {
  late final _phrase = TextEditingController(text: ref.read(wakeWordProvider).phrase);
  late var _enabled = ref.read(wakeWordProvider).enabled;
  late String? _bot = ref.read(wakeWordProvider).botId;
  double? _progress;
  var _busy = false;
  StreamSubscription<void>? _testSub;
  var _testing = false;
  var _heard = false;
  late final _controller = ref.read(wakeWordProvider.notifier);

  @override
  void dispose() {
    unawaited(_testSub?.cancel());
    if (_testing) unawaited(_controller.stopTest());
    _phrase.dispose();
    super.dispose();
  }

  Future<void> _startTest() async {
    await _stopTest();
    if (!mounted) return;
    setState(() {
      _testing = true;
      _heard = false;
    });
    final phrase = _phrase.text.trim().toLowerCase();
    final stream = await runGuarded(
      context,
      () => _controller.startTest(
        phrase,
        onProgress: (p) => mounted ? setState(() => _progress = p) : null,
      ),
    );
    if (!mounted) {
      unawaited(_controller.stopTest());
      return;
    }
    if (stream == null) {
      setState(() => _testing = false);
      return;
    }
    _testSub = stream.listen(
      (_) {
        if (!mounted) return;
        HapticsHelper.medium();
        setState(() {
          _heard = true;
          _testing = false;
        });
        unawaited(_stopTest(keepHeard: true));
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() => _testing = false);
        unawaited(_controller.stopTest());
      },
    );
  }

  Future<void> _stopTest({bool keepHeard = false}) async {
    await _testSub?.cancel();
    _testSub = null;
    if (_testing || keepHeard) await _controller.stopTest();
    if (mounted) {
      setState(() {
        _testing = false;
        if (!keepHeard) _heard = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    if (_bot != null && !bots.any((b) => b.id == _bot)) _bot = null;
    _bot ??= bots.firstOrNull?.id;
    final valid = !_enabled || (_bot != null && _phrase.text.trim().split(RegExp(r'\s+')).length >= 2);
    return FormSheet(
      icon: LucideIcons.audioLines,
      title: l10n.wakeWord,
      subtitle: l10n.wakeWordHelp,
      submitLabel: l10n.save,
      submitKey: const Key('saveWakeWord'),
      busy: _busy,
      onSubmit: !valid || _busy
          ? null
          : () async {
              setState(() => _busy = true);
              final r = await runGuarded(
                context,
                () => ref
                    .read(wakeWordProvider.notifier)
                    .save(
                      WakeWordSettings(enabled: _enabled, phrase: _phrase.text.trim().toLowerCase(), botId: _bot),
                      onProgress: (p) => mounted ? setState(() => _progress = p) : null,
                    )
                    .then((_) => true),
              );
              if (!mounted) return;
              setState(() => _busy = false);
              if (!context.mounted) return;
              if (r == true) Navigator.pop(context);
            },
      children: [
        SwitchListTile(key: const Key('wakeWordOn'), contentPadding: EdgeInsets.zero, title: Text(l10n.wakeWordListen), value: _enabled, onChanged: hapticOnChanged((v) => setState(() => _enabled = v))),
        TextField(
          key: const Key('wakePhrase'),
          controller: _phrase,
          onChanged: (_) => setState(() => _heard = false),
          decoration: InputDecoration(labelText: l10n.wakeWordPhrase, helperText: l10n.wakeWordPhraseHelp),
        ),
        Row(
          children: [
            if (_testing)
              OutlinedButton.icon(
                key: const Key('stopWakeTest'),
                onPressed: () => unawaited(_stopTest()),
                icon: const Icon(LucideIcons.square, size: 16),
                label: Text(l10n.wakeWordStopTest),
              )
            else
              OutlinedButton.icon(
                key: const Key('testWakeWord'),
                onPressed: _busy || _phrase.text.trim().split(RegExp(r'\s+')).length < 2 ? null : () => unawaited(_startTest()),
                icon: const Icon(LucideIcons.mic, size: 16),
                label: Text(l10n.wakeWordTest),
              ),
            const SizedBox(width: 12),
            if (_testing)
              Expanded(child: Text(l10n.wakeWordTesting, style: context.textTheme.bodySmall))
            else if (_heard)
              Expanded(
                child: Row(
                  children: [
                    Icon(LucideIcons.check, size: 16, color: context.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(l10n.wakeWordHeard, style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.primary)),
                  ],
                ),
              ),
          ],
        ),
        DropdownButtonFormField<String>(
          isExpanded: true,
          key: const Key('wakeBot'),
          initialValue: _bot,
          decoration: InputDecoration(labelText: l10n.wakeWordBot),
          items: [for (final b in bots) DropdownMenuItem(value: b.id, child: Text(b.name))],
          onChanged: hapticOnChanged((v) => setState(() => _bot = v), haptic: HapticsHelper.selection),
        ),
        if (_progress != null && _progress! < 1) ...[Text(l10n.wakeWordDownloading), LinearProgressIndicator(value: _progress)],
        FormNote(l10n.wakeWordPrivacy),
      ],
    );
  }
}

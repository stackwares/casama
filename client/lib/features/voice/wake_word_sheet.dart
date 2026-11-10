import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
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

  @override
  void dispose() {
    _phrase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
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
              if (r == true) Navigator.pop(context);
            },
      children: [
        SwitchListTile(key: const Key('wakeWordOn'), contentPadding: EdgeInsets.zero, title: Text(l10n.wakeWordListen), value: _enabled, onChanged: (v) => setState(() => _enabled = v)),
        TextField(
          key: const Key('wakePhrase'),
          controller: _phrase,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.wakeWordPhrase, helperText: l10n.wakeWordPhraseHelp),
        ),
        DropdownButtonFormField<String>(
          key: const Key('wakeBot'),
          initialValue: _bot,
          decoration: InputDecoration(labelText: l10n.wakeWordBot),
          items: [for (final b in bots) DropdownMenuItem(value: b.id, child: Text(b.name))],
          onChanged: (v) => setState(() => _bot = v),
        ),
        if (_progress != null && _progress! < 1) ...[Text(l10n.wakeWordDownloading), LinearProgressIndicator(value: _progress)],
        FormNote(l10n.wakeWordPrivacy),
      ],
    );
  }
}

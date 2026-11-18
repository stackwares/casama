import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';

/// Which kinds of notification push (D-325). Every kind still lands in the inbox; a kind that's
/// off only stops buzzing the phone. Null when the server doesn't have the setting (older than
/// D-325), so the row stays out of sight.
final pushPrefsProvider = FutureProvider.autoDispose<PushPrefs?>((ref) async {
  if (ref.watch(signedInProvider).value != true) return null;
  try {
    return await ref.watch(backendProvider).pushPrefs();
  } catch (_) {
    return null;
  }
});

/// "All on", "Replies off", "3 kinds off": what the settings row says under its title.
String pushPrefsSummary(BuildContext context, PushPrefs p) {
  final l10n = context.l10n;
  final off = [if (!p.replies) l10n.pushReplies, if (!p.needsYou) l10n.pushNeedsYou, if (!p.routines) l10n.pushRoutines, if (!p.suggestions) l10n.pushSuggestions, if (!p.account) l10n.pushAccount];
  if (off.isEmpty) return l10n.pushAllOn;
  if (off.length == 1) return l10n.pushOneOff(off.single);
  return l10n.pushSomeOff(off.length);
}

class PushPrefsTile extends ConsumerWidget {
  const PushPrefsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(pushPrefsProvider).value;
    if (prefs == null) return const SizedBox.shrink();
    return GroupedTile(
      key: const Key('settingsPushPrefs'),
      icon: LucideIcons.bellRing,
      title: context.l10n.pushPrefsTitle,
      subtitle: pushPrefsSummary(context, prefs),
      onTap: () => showPushPrefs(context, ref),
    );
  }
}

Future<void> showPushPrefs(BuildContext context, WidgetRef ref) async {
  final current = await ref.read(pushPrefsProvider.future);
  if (current == null || !context.mounted) return;
  final picked = await showAdaptiveSheet<PushPrefs>(
    context: context,
    builder: (_) => PushPrefsSheet(initial: current),
  );
  if (picked == null || !context.mounted) return;
  await runGuarded(context, () => ref.read(backendProvider).setPushPrefs(picked));
  ref.invalidate(pushPrefsProvider);
}

class PushPrefsSheet extends StatefulWidget {
  const PushPrefsSheet({super.key, required this.initial});

  final PushPrefs initial;

  @override
  State<PushPrefsSheet> createState() => _PushPrefsSheetState();
}

class _PushPrefsSheetState extends State<PushPrefsSheet> {
  late PushPrefs _p = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget row(String key, String title, String help, bool value, PushPrefs Function(bool) set) =>
        SwitchListTile(key: Key(key), contentPadding: EdgeInsets.zero, title: Text(title), subtitle: Text(help), value: value, onChanged: hapticOnChanged((v) => setState(() => _p = set(v))));
    return FormSheet(
      icon: LucideIcons.bellRing,
      title: l10n.pushPrefsTitle,
      subtitle: l10n.pushPrefsHelp,
      submitLabel: l10n.save,
      submitKey: const Key('savePushPrefs'),
      onSubmit: () => Navigator.pop(context, _p),
      children: [
        row('pushReplies', l10n.pushReplies, l10n.pushRepliesHelp, _p.replies, (v) => _p.copyWith(replies: v)),
        row('pushNeedsYou', l10n.pushNeedsYou, _p.needsYou ? l10n.pushNeedsYouHelp : l10n.pushNeedsYouOffWarning, _p.needsYou, (v) => _p.copyWith(needsYou: v)),
        row('pushRoutines', l10n.pushRoutines, l10n.pushRoutinesHelp, _p.routines, (v) => _p.copyWith(routines: v)),
        row('pushSuggestions', l10n.pushSuggestions, l10n.pushSuggestionsHelp, _p.suggestions, (v) => _p.copyWith(suggestions: v)),
        row('pushAccount', l10n.pushAccount, l10n.pushAccountHelp, _p.account, (v) => _p.copyWith(account: v)),
        const Divider(),
        row('pushHideReplyText', l10n.pushHideReplyText, l10n.pushHideReplyTextHelp, _p.hideReplyText, (v) => _p.copyWith(hideReplyText: v)),
      ],
    );
  }
}

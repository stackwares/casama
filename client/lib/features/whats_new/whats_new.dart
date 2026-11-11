import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/push.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';
import '../settings/name_step.dart';

/// What changed for people in each version, newest first, in plain words: what someone will notice,
/// not how it was built (CHANGELOG.md is the developers' record). When pubspec.yaml's version goes
/// up, add that version at the top with three to five lines, each a string in app_en.arb named
/// whatsNew<version><Topic>. test/whats_new_test.dart fails until the current version has lines.
Map<String, List<String>> whatsNewByVersion(AppLocalizations l10n) => {
  '0.8.0': [l10n.whatsNew080Calls, l10n.whatsNew080Looks, l10n.whatsNew080AboutYou, l10n.whatsNew080SignIn],
};

/// The version whose lines were shown last, or the version first opened.
const whatsNewSeenKey = 'whatsNew.lastSeenVersion';

Version? _version(String value) {
  try {
    return Version.parse(value);
  } on FormatException {
    return null;
  }
}

/// The lines of every version after [lastSeen] up to and including [current], newest first, so
/// someone who skipped updates sees all they missed. Empty when a version can't be read.
List<String> unseenChanges({required String lastSeen, required String current, required Map<String, List<String>> changelog}) {
  final seen = _version(lastSeen);
  final now = _version(current);
  if (seen == null || now == null) return const <String>[];
  final result = <String>[];
  for (final entry in changelog.entries) {
    final version = _version(entry.key);
    if (version != null && version > seen && version <= now) result.addAll(entry.value);
  }
  return result;
}

/// Shows what's new once, the first time the signed-in app opens after an update. Never on a fresh
/// install (the version is only remembered), never over sign-in, the welcome chat or onboarding
/// (it wraps only the signed-in shell), and not over the name or notifications pages or another
/// sheet: then it waits for the next open.
class WhatsNewGate extends ConsumerStatefulWidget {
  const WhatsNewGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<WhatsNewGate> createState() => _WhatsNewGateState();
}

class _WhatsNewGateState extends ConsumerState<WhatsNewGate> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Let the first screen settle before anything slides over it.
    _timer = Timer(const Duration(milliseconds: 800), _check);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (!mounted) return;
    final l10n = context.l10n;
    try {
      final current = (await PackageInfo.fromPlatform()).version;
      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getString(whatsNewSeenKey);
      final lines = lastSeen == null ? const <String>[] : unseenChanges(lastSeen: lastSeen, current: current, changelog: whatsNewByVersion(l10n));
      // A fresh install (nothing seen yet), the same version, or an update with no lines.
      if (lines.isEmpty) {
        if (lastSeen != current) await prefs.setString(whatsNewSeenKey, current);
        return;
      }
      if (!mounted) return;
      // Not over the name or notifications pages, or over another sheet: next open instead.
      if ((ref.read(nameStepNeededProvider) ?? false) || ref.read(pushProvider).needsAsk.value) return;
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
      // Seen the moment it shows, so it never comes back for this version.
      await prefs.setString(whatsNewSeenKey, current);
      if (!mounted) return;
      await showWhatsNew(context, version: current, lines: lines);
    } catch (_) {
      // No version or preferences (widget tests, a locked keychain): nothing to show.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The list of what's new in [version], in the app's adaptive sheet (a sheet on phones, a dialog on
/// larger windows).
Future<void> showWhatsNew(BuildContext context, {required String version, required List<String> lines}) {
  final l10n = context.l10n;
  return showAdaptiveSheet<void>(
    context: context,
    dialogMaxWidth: 460,
    builder: (c) => FormSheet(
      key: const Key('whatsNewSheet'),
      icon: LucideIcons.sparkles,
      title: l10n.whatsNewTitle(version),
      submitLabel: l10n.whatsNewGotIt,
      submitKey: const Key('whatsNewDone'),
      showCancel: false,
      onSubmit: () => Navigator.pop(c),
      children: [for (final line in lines) _Line(line)],
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Icon(LucideIcons.check, size: 18, color: context.colorScheme.primary),
      ),
      const SizedBox(width: AppSpace.sm),
      Expanded(child: Text(text, style: context.textTheme.bodyLarge?.copyWith(height: 1.4))),
    ],
  );
}

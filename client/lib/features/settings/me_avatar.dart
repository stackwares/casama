import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import 'about_you_screen.dart';

/// The signed-in person's initial in an accent-tinted circle.
class MeAvatar extends ConsumerWidget {
  const MeAvatar({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final label = meLabel(ref);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.16), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        label.isEmpty ? '?' : label.characters.first.toUpperCase(),
        style: context.textTheme.titleSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w800, fontSize: size * 0.42, height: 1),
      ),
    );
  }
}

/// The name bots use for the signed-in person, else their email.
String meLabel(WidgetRef ref) {
  final name = ref.watch(aboutYouProvider).value?.name ?? '';
  return name.isNotEmpty ? name : (ref.watch(backendProvider).userEmail ?? '');
}

/// The way into Settings from the chats on phones and from the rail on tablets: the person's
/// avatar, which pushes Settings so back returns to where they were.
class MeButton extends StatelessWidget {
  const MeButton({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: context.l10n.settings,
    child: Semantics(
      button: true,
      label: context.l10n.settings,
      child: InkWell(
        key: const Key('meButton'),
        customBorder: const CircleBorder(),
        onTap: () => context.push('/settings'),
        child: MeAvatar(size: size),
      ),
    ),
  );
}

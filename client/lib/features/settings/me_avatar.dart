import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../ui/person_avatar.dart';
import 'about_you_screen.dart';
import 'profile_photo.dart';

/// The signed-in person's profile photo (D-202), else their initial in an accent-tinted circle.
class MeAvatar extends ConsumerWidget {
  const MeAvatar({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PersonAvatar(label: meLabel(ref), photoUrl: myPhotoUrl(ref), size: size);
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

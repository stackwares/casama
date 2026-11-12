import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dev_server.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../ui/person_avatar.dart';
import 'about_you_screen.dart';
import 'profile_photo.dart';

/// The signed-in person's profile photo (D-202), else their initial in an accent-tinted circle.
/// On a development server (the local stack or api-dev.casama.ai) it carries a small amber dot,
/// so you can always tell a test session from production.
class MeAvatar extends ConsumerWidget {
  const MeAvatar({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = PersonAvatar(label: meLabel(ref), photoUrl: myPhotoUrl(ref), size: size);
    if (!isDevServer(ref.watch(backendProvider).apiUrl)) return avatar;
    final dot = (size * 0.3).clamp(8.0, 14.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              key: const Key('devServerDot'),
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
              ),
            ),
          ),
        ],
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
class MeButton extends ConsumerWidget {
  const MeButton({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(backendProvider).apiUrl;
    final label = isDevServer(url) ? context.l10n.settingsOnDevServer(serverHost(url)) : context.l10n.settings;
    return Tooltip(
    message: label,
    child: Semantics(
      button: true,
      label: label,
      child: InkWell(
        key: const Key('meButton'),
        customBorder: const CircleBorder(),
        onTap: () => context.push('/settings'),
        child: MeAvatar(size: size),
      ),
    ),
  );
  }
}

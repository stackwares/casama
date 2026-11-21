import 'package:material_ui/material_ui.dart';

import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/ambient_motion.dart';
import '../../ui/mascot.dart';
import '../../ui/splash_scene.dart';
import 'setup_screen.dart';

/// Pictures for the guided setup (docs/SETUP-SCREEN-PLAN.md): on a wide window a panel with the
/// painted "coming home" scene and a cloud bot floating in its sky, one bot per step; on a narrow
/// one just the bot above the step.

/// Windows at least this wide get the two panes.
const setupWideWidth = 900.0;

/// The bot and its line for [stage]; null while the page is still deciding.
(Mascot, String)? setupArtFor(SetupStage? stage, AppLocalizations l10n) => switch (stage) {
  null => null,
  SetupStage.docker => (Mascot.thinker, l10n.setupArtDocker),
  SetupStage.server => (Mascot.focused, l10n.setupArtServer),
  SetupStage.account => (Mascot.wow, l10n.setupArtAccount),
  SetupStage.model => (Mascot.starry, l10n.setupArtModel),
  SetupStage.phone => (Mascot.winky, l10n.setupArtPhone),
};

/// The bot for [stage], swapped with a short scale-and-fade when the step changes.
class SetupMascot extends StatelessWidget {
  const SetupMascot({super.key, required this.stage, required this.size});
  final SetupStage? stage;
  final double size;

  @override
  Widget build(BuildContext context) {
    final art = setupArtFor(stage, context.l10n);
    return SizedBox.square(
      dimension: size,
      child: AnimatedSwitcher(
        duration: AppMotion.of(context, AppMotion.duration),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: Tween(begin: 0.8, end: 1.0).animate(animation), child: child),
        ),
        child: art == null
            ? const SizedBox.shrink()
            : MascotImage(
                art.$1,
                key: ValueKey(art.$1),
                size: size,
                animate: ambientMotionOn(context),
                semanticLabel: art.$1.label,
              ),
      ),
    );
  }
}

/// The left panel on a wide window: the scene (tall cut, decoded at the panel's size), the bot in
/// its sky and the step's line under it.
class SetupArtPane extends StatelessWidget {
  const SetupArtPane({super.key, required this.stage});
  final SetupStage? stage;

  @override
  Widget build(BuildContext context) {
    final art = setupArtFor(stage, context.l10n);
    final scheme = context.colorScheme;
    return ClipRRect(
      key: const Key('setupArtPane'),
      borderRadius: BorderRadius.circular(28),
      child: LayoutBuilder(
        builder: (context, box) {
          final mascot = (box.maxWidth * 0.42).clamp(140.0, 220.0);
          return Stack(
            fit: StackFit.expand,
            children: [
              // SplashScene picks its cut and decode size from the screen; give it the panel's.
              MediaQuery(
                data: MediaQuery.of(context).copyWith(size: box.biggest),
                child: SplashScene(brightness: Theme.of(context).brightness, background: scheme.surfaceContainer),
              ),
              Align(
                alignment: const Alignment(0, -0.25),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: AppSpace.md,
                    children: [
                      SetupMascot(stage: stage, size: mascot),
                      AnimatedSwitcher(
                        duration: AppMotion.of(context, AppMotion.duration),
                        child: art == null
                            ? const SizedBox.shrink()
                            : _Caption(art.$2, key: ValueKey(art.$2)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The step's line on the painting, on a soft pill so it reads over day and night.
class _Caption extends StatelessWidget {
  const _Caption(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: (dark ? Colors.black : Colors.white).withValues(alpha: dark ? 0.38 : 0.62),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
        child: Text(
          text,
          key: const Key('setupArtCaption'),
          textAlign: TextAlign.center,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: dark ? Colors.white : const Color(0xFF1C1C1E),
          ),
        ),
      ),
    );
  }
}

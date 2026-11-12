import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bottom_padding.dart';
import '../../ui/mascot.dart';
import '../../ui/progressive_fade.dart';
import 'about_you_screen.dart';
import '../../core/analytics.dart';

/// This session already finished the name step, so it hides at once instead of waiting for the
/// profile to reload.
class _NameStepDone extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(signedInProvider);
    return false;
  }

  void finish() => state = true;
}

final _nameStepDoneProvider = NotifierProvider<_NameStepDone, bool>(
  _NameStepDone.new,
);

/// Whether the full-screen name step should show (About you, D-169): signed in all the way
/// (after the two-step code and any new password, [signInFinishedProvider]), and "What should
/// bots call you?" never answered or skipped. Null while the profile is still loading. If it
/// can't load, the step stays out of the way.
final nameStepNeededProvider = Provider.autoDispose<bool?>((ref) {
  if (!ref.watch(signInFinishedProvider)) return false;
  if (ref.watch(_nameStepDoneProvider)) return false;
  return ref
      .watch(aboutYouProvider)
      .when(
        data: (a) => !a.nameAsked,
        loading: () => null,
        error: (_, _) => false,
      );
});

/// "What should bots call you?", once after sign-in, full screen like "Turn on notifications"
/// and before it: a bot, the question, the sign-in first name filled in, and "Continue". "Not now"
/// counts as asked, so it never comes back. The welcome chat waits for it, so it doesn't ask
/// again (the server skips its own name question once this is answered).
class NameStep extends StatelessWidget {
  const NameStep({super.key});

  // Its own overlay, because it sits above the app's navigator and the text field needs one for
  // its selection handles and menu.
  @override
  Widget build(BuildContext context) => Overlay(
    initialEntries: [OverlayEntry(builder: (_) => const _NamePage())],
  );
}

class _NamePage extends ConsumerStatefulWidget {
  const _NamePage();

  @override
  ConsumerState<_NamePage> createState() => _NamePageState();
}

class _NamePageState extends ConsumerState<_NamePage> {
  final _name = TextEditingController();
  var _filled = false;
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool save}) async {
    final about = ref.read(aboutYouProvider).value;
    if (about == null || _busy) return;
    final name = _name.text.trim();
    setState(() => _busy = true);
    final backend = ref.read(backendProvider);
    final ok = await runGuarded(context, () async {
      if (save && name.isNotEmpty) {
        await backend.saveAboutYou(about.copyWith(preferredName: name));
      } else {
        await backend.markNameAsked();
      }
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok == true) {
      Analytics.log('onboarding_step_done', {'step': 'name_overlay', 'action': save && name.isNotEmpty ? 'saved' : 'skipped'});
      ref.read(_nameStepDoneProvider.notifier).finish();
      ref.invalidate(aboutYouProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final about = ref.watch(aboutYouProvider).value;
    if (!_filled && about != null) {
      _filled = true;
      _name.text = about.name;
    }
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final canSave = !_busy && _name.text.trim().isNotEmpty;
    final statusBar = MediaQuery.paddingOf(context).top;
    return Scaffold(
      key: const Key('nameStep'),
      backgroundColor: scheme.surface,
      body: ProgressiveFade(child: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            // Spaced out when it fits; scrolls when the keyboard or large text doesn't.
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                // Starts under the status bar, so content dissolves there as it scrolls up.
                padding: EdgeInsets.only(top: statusBar),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: (constraints.maxHeight - statusBar).clamp(0.0, double.infinity)),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpace.xl,
                        0,
                        AppSpace.xl,
                        BottomPadding.of(context, minimum: AppSpace.md),
                      ),
                      child: Column(
                        children: [
                          const Spacer(flex: 5),
                          // The bot, with what it's saying above it.
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Text(
                              l10n.nameStepBubble,
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Container(
                            width: 132,
                            height: 132,
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const MascotImage(Mascot.winky, size: 104),
                          ),
                          const SizedBox(height: AppSpace.xl),
                          Text(
                            l10n.whatToCallYou,
                            textAlign: TextAlign.center,
                            style: context.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: AppSpace.sm),
                          Text(
                            l10n.nameCardHelp,
                            textAlign: TextAlign.center,
                            style: context.textTheme.titleMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: AppSpace.xl),
                          TextField(
                            key: const Key('nameStepField'),
                            controller: _name,
                            maxLength: 60,
                            textAlign: TextAlign.center,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.givenName],
                            style: context.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: l10n.nameStepHint,
                            ),
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) {
                              if (canSave) _finish(save: true);
                            },
                          ),
                          const Spacer(flex: 6),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              key: const Key('nameStepContinue'),
                              style: FilledButton.styleFrom(
                                backgroundColor: scheme.onSurface,
                                foregroundColor: scheme.surface,
                                shape: const StadiumBorder(),
                                minimumSize: const Size.fromHeight(56),
                                textStyle: context.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              onPressed: canSave
                                  ? () => _finish(save: true)
                                  : null,
                              child: Text(l10n.continueLabel),
                            ),
                          ),
                          const SizedBox(height: AppSpace.xs),
                          TextButton(
                            key: const Key('nameStepLater'),
                            onPressed: _busy
                                ? null
                                : () => _finish(save: false),
                            child: Text(
                              l10n.notNow,
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      )),
    );
  }
}

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/backend.dart';
import '../../core/number_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/glow_button.dart';
import '../../ui/page.dart';
import '../bots/agent_import.dart';
import 'profile_photo.dart';

final aboutYouProvider = FutureProvider<AboutYouView>((ref) async {
  if (ref.watch(signedInProvider).value == false) return const AboutYouView();
  final backend = ref.watch(backendProvider);
  final about = await backend.aboutYou();
  // Signed in with Google and no photo yet (D-202): copy the Google photo once. The server does
  // it only the first time, so a removed photo stays removed.
  if (about.photoId == null && about.providerPhoto && !about.photoImportTried) {
    try {
      return await backend.importProfilePhoto();
    } catch (_) {
      return about;
    }
  }
  return about;
});
final userFactsProvider = FutureProvider<List<UserFactView>>((ref) => ref.watch(backendProvider).userFacts());
final profileSharedProvider = FutureProvider.family<bool, String>((ref, orgId) => ref.watch(backendProvider).profileSharedIn(orgId));

/// About you (D-169): what bots call the person, how they like replies, what they shared, and the
/// facts bots learned in chat. Private to the person.
class AboutYouScreen extends ConsumerStatefulWidget {
  const AboutYouScreen({super.key});

  @override
  ConsumerState<AboutYouScreen> createState() => _AboutYouScreenState();
}

class _AboutYouScreenState extends ConsumerState<AboutYouScreen> {
  final _name = TextEditingController();
  final _pronouns = TextEditingController();
  final _about = TextEditingController();
  final _style = TextEditingController();
  AboutYouView? _loaded;
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _pronouns.dispose();
    _about.dispose();
    _style.dispose();
    super.dispose();
  }

  void _fill(AboutYouView v) {
    _loaded = v;
    _name.text = v.name;
    _pronouns.text = v.pronouns ?? '';
    _about.text = v.about;
    _style.text = v.replyStyle;
  }

  bool get _dirty {
    final v = _loaded;
    if (v == null) return false;
    return _name.text.trim() != v.name || _pronouns.text.trim() != (v.pronouns ?? '') || _about.text.trim() != v.about || _style.text.trim() != v.replyStyle;
  }

  Future<void> _save({bool? learn}) async {
    final v = _loaded;
    if (v == null) return;
    final next = v.copyWith(preferredName: _name.text.trim(), pronouns: _pronouns.text.trim(), about: _about.text.trim(), replyStyle: _style.text.trim(), learn: learn);
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref.read(backendProvider).saveAboutYou(next);
      return true;
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok == true) _loaded = next;
    });
    if (ok == true && learn == null) showSuccess(context, context.l10n.saved);
  }

  Future<void> _editFact({UserFactView? fact}) async {
    final text = await showAdaptiveSheet<String>(
      context: context,
      builder: (_) => _FactForm(initial: fact?.content ?? ''),
    );
    if (text == null || text.isEmpty || !mounted) return;
    final backend = ref.read(backendProvider);
    await runGuarded(context, () => fact == null ? backend.addUserFacts([(kind: 'fact', content: text)]) : backend.updateUserFact(fact.id, content: text));
    ref.invalidate(userFactsProvider);
  }

  Future<void> _deleteFact(UserFactView fact) async {
    final l10n = context.l10n;
    final ok = await showConfirm(context: context, title: l10n.deleteFactTitle, message: l10n.deleteFactConfirm, confirmLabel: l10n.delete, destructive: true);
    if (!ok || !mounted) return;
    await runGuarded(context, () => ref.read(backendProvider).deleteUserFact(fact.id));
    ref.invalidate(userFactsProvider);
  }

  Future<void> _import() async {
    final l10n = context.l10n;
    final n = await showAdaptiveSheet<int>(context: context, builder: (_) => const MemoryImportSheet());
    ref.invalidate(userFactsProvider);
    if (n != null && mounted) showSuccess(context, l10n.factsImported(n));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final about = ref.watch(aboutYouProvider);
    final facts = ref.watch(userFactsProvider);
    final org = ref.watch(currentOrgProvider);
    final v = about.value;
    if (v != null && _loaded == null) _fill(v);
    if (v == null) {
      return SubPage(
        title: l10n.aboutYou,
        body: AsyncView(value: about, onRetry: () => ref.invalidate(aboutYouProvider), data: (_) => const SizedBox.shrink()),
      );
    }
    final learn = _loaded?.learn ?? true;
    return SubPage(
      title: l10n.aboutYou,
      actions: [IconButton(key: const Key('importToProfile'), tooltip: l10n.importToProfile, icon: const Icon(LucideIcons.download), onPressed: _import)],
      children: [
        Center(child: ProfilePhotoEditor(label: v.name.isNotEmpty ? v.name : (ref.watch(backendProvider).userEmail ?? ''))),
        const SizedBox(height: AppSpace.md),
        FormNote(l10n.aboutYouIntro, icon: LucideIcons.lock),
        const SizedBox(height: AppSpace.md),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.md,
            children: [
              TextField(
                key: const Key('aboutName'),
                controller: _name,
                textInputAction: TextInputAction.next,
                maxLength: 60,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.whatToCallYou, counterText: ''),
                onChanged: (_) => setState(() {}),
              ),
              TextField(
                key: const Key('aboutPronouns'),
                controller: _pronouns,
                textInputAction: TextInputAction.next,
                maxLength: 40,
                decoration: InputDecoration(labelText: l10n.pronounsOptional, counterText: ''),
                onChanged: (_) => setState(() {}),
              ),
              TextField(
                key: const Key('aboutStyle'),
                controller: _style,
                maxLength: 600,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(labelText: l10n.replyStyle, hintText: l10n.replyStyleHint, alignLabelWithHint: true),
                onChanged: (_) => setState(() {}),
              ),
              TextField(
                key: const Key('aboutMe'),
                controller: _about,
                maxLength: 1500,
                minLines: 3,
                maxLines: 10,
                decoration: InputDecoration(labelText: l10n.aboutMe, hintText: l10n.aboutMeHint, alignLabelWithHint: true),
                onChanged: (_) => setState(() {}),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: GlowButton(key: const Key('aboutSave'), onPressed: _busy || !_dirty ? null : _save, child: Text(l10n.save)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        GroupedCard(
          children: [
            SwitchListTile(
              key: const Key('learnAboutMe'),
              secondary: Icon(LucideIcons.sparkles, color: scheme.onSurfaceVariant),
              title: Text(l10n.learnAboutMe),
              subtitle: Text(l10n.learnAboutMeHelp),
              value: learn,
              onChanged: hapticOnChanged(_busy ? null : (on) => _save(learn: on)),
            ),
            if (org != null)
              SwitchListTile(
                key: const Key('useInThisSpace'),
                secondary: Icon(LucideIcons.boxes, color: scheme.onSurfaceVariant),
                title: Text(l10n.useInThisSpace(org.name)),
                subtitle: Text(l10n.useInThisSpaceHelp),
                value: ref.watch(profileSharedProvider(org.id)).value ?? false,
                onChanged: hapticOnChanged((on) async {
                  await runGuarded(context, () => ref.read(backendProvider).setProfileSharedIn(org.id, on));
                  ref.invalidate(profileSharedProvider(org.id));
                }),
              ),
          ],
        ),
        SectionHeader(
          title: l10n.learnedAboutYou,
          count: facts.value?.length.humanizedCount(context.l10n.localeName),
          trailing: TextButton.icon(key: const Key('addFact'), icon: const Icon(LucideIcons.plus, size: 16), label: Text(l10n.addFact), onPressed: () => _editFact()),
        ),
        AsyncView(
          value: facts,
          onRetry: () => ref.invalidate(userFactsProvider),
          data: (items) => items.isEmpty
              ? FormNote(l10n.noLearnedFacts, icon: LucideIcons.brain)
              : GroupedCard(
                  dividerIndent: AppSpace.md,
                  children: [
                    for (final f in items)
                      _FactRow(
                        key: Key('fact-${f.id}'),
                        fact: f,
                        onEdit: () => _editFact(fact: f),
                        onDelete: () => _deleteFact(f),
                        onPin: () async {
                          await runGuarded(context, () => ref.read(backendProvider).updateUserFact(f.id, pinned: !f.pinned));
                          ref.invalidate(userFactsProvider);
                        },
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({super.key, required this.fact, required this.onEdit, required this.onDelete, required this.onPin});
  final UserFactView fact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return ListTile(
      onTap: onEdit,
      leading: Icon(fact.pinned ? LucideIcons.pin : (fact.kind == 'preference' ? LucideIcons.heart : LucideIcons.lightbulb), size: 18, color: fact.pinned ? scheme.primary : context.appColors.info),
      title: Text(fact.content, style: context.textTheme.bodyMedium?.copyWith(height: 1.4)),
      trailing: PopupMenuButton<String>(
        tooltip: l10n.moreActions,
        onOpened: unfocusBeforeModal,
        icon: Icon(LucideIcons.ellipsisVertical, color: scheme.onSurfaceVariant),
        onSelected: (v) => switch (v) {
          'edit' => onEdit(),
          'pin' => onPin(),
          _ => onDelete(),
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'edit',
            child: ListTile(leading: const Icon(LucideIcons.pencil), title: Text(l10n.edit), dense: true),
          ),
          PopupMenuItem(
            value: 'pin',
            child: ListTile(leading: Icon(fact.pinned ? LucideIcons.pinOff : LucideIcons.pin), title: Text(fact.pinned ? l10n.unpin : l10n.pin), dense: true),
          ),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(LucideIcons.trash2, color: scheme.error),
              title: Text(l10n.delete, style: TextStyle(color: scheme.error)),
              dense: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _FactForm extends StatefulWidget {
  const _FactForm({required this.initial});
  final String initial;

  @override
  State<_FactForm> createState() => _FactFormState();
}

class _FactFormState extends State<_FactForm> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.lightbulb,
      title: widget.initial.isEmpty ? l10n.addFact : l10n.editFact,
      submitLabel: l10n.save,
      submitKey: const Key('factSave'),
      onSubmit: _text.text.trim().isEmpty ? null : () => Navigator.pop(context, _text.text.trim()),
      children: [TextField(key: const Key('factText'), controller: _text, autofocus: true, maxLength: 500, minLines: 2, maxLines: 6, onChanged: (_) => setState(() {}))],
    );
  }
}

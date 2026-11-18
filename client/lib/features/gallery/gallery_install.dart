import 'package:casama_sdk/casama_sdk.dart' show Bot, CatalogApp;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';
import '../integrations/app_logo.dart';
import '../integrations/connect_app_sheet.dart';
import '../integrations/integrations_screen.dart' show connectedAppIdsProvider;
import '../settings/gallery_looks.dart';
import 'gallery_cards.dart';
import 'gallery_data.dart';
import 'gallery_detail_parts.dart';
import 'gallery_logic.dart';

/// Installs a gallery item, walking the person through what it asks and needs (D-315): its
/// questions (inputs), then the skills it installs and the apps to connect one by one, then done.
/// Works for every kind; looks apply at once, skills, apps and plugins skip the steps they don't
/// have. Returns true once the item is installed (or waiting for an admin's approval).
Future<bool> showGalleryInstall(
  BuildContext context,
  WidgetRef ref, {
  required String type,
  required String id,
}) async {
  final l10n = context.l10n;
  final backend = ref.read(backendProvider);
  var item = ref.read(galleryCatalogProvider).value?.find(type, id);
  final needsDocument = galleryLookKinds.contains(type) || type == 'set';
  if (item == null || (needsDocument && item.document == null)) {
    item = await runGuarded<GalleryItem>(
      context,
      () => backend.galleryItem(type, id),
    );
  }
  if (item == null || !context.mounted) return false;
  if (galleryLookKinds.contains(type)) {
    final full = item;
    final done = await runGuarded<bool>(context, () async {
      await applyGalleryItem(ref, full);
      return true;
    });
    if (done == true && context.mounted) {
      showSuccess(context, l10n.galleryApplied(full.name));
    }
    return done == true;
  }
  final org = ref.read(currentOrgProvider);
  if (org == null) return false;
  final ok = await showAdaptiveSheet<bool>(
    context: context,
    dialogMaxWidth: 560,
    builder: (_) => GalleryInstallWizard(item: item!, orgId: org.id),
  );
  return ok ?? false;
}

enum _Step { review, needs, done }

/// The install steps in one sheet: review and answers, then what's still needed, then done.
class GalleryInstallWizard extends ConsumerStatefulWidget {
  const GalleryInstallWizard({
    super.key,
    required this.item,
    required this.orgId,
  });
  final GalleryItem item;
  final String orgId;

  @override
  ConsumerState<GalleryInstallWizard> createState() =>
      _GalleryInstallWizardState();
}

class _GalleryInstallWizardState extends ConsumerState<GalleryInstallWizard> {
  var _step = _Step.review;
  var _busy = false;
  final _answers = <String, String>{};
  final _controllers = <String, TextEditingController>{};
  var _errors = <String, String>{};
  String? _botId;
  GalleryInstallResult _result = const GalleryInstallResult();
  final _connected = <String>{};

  GalleryItem get _item => widget.item;

  @override
  void initState() {
    super.initState();
    for (final input in _item.inputs) {
      final value = input.defaultValue ?? '';
      _answers[input.key] = value;
      if (input.type == 'text' || input.type == 'timezone') {
        _controllers[input.key] = TextEditingController(text: value)
          ..addListener(() {
            _answers[input.key] = _controllers[input.key]!.text;
          });
      }
      if (input.type == 'timezone' && value.isEmpty) _fillTimezone(input.key);
    }
  }

  Future<void> _fillTimezone(String key) async {
    try {
      final tz = (await FlutterTimezone.getLocalTimezone()).identifier;
      if (mounted && (_controllers[key]?.text.isEmpty ?? false)) {
        _controllers[key]!.text = tz;
      }
    } catch (_) {
      // Left for the person to type.
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Routines and plugins go to a bot; the server turns them down without one.
  bool get _needsBot => _item.type == 'routine' || _item.type == 'plugin';

  /// A set with routines or plugins and no bot of its own offers a bot for them (optional:
  /// without one they're skipped).
  bool _setWantsBot(List<GalleryItem> setItems) =>
      _item.type == 'set' &&
      setItems.any((i) => i.type == 'routine' || i.type == 'plugin') &&
      !setItems.any((i) => i.type == 'bot');

  bool _validate() {
    final l10n = context.l10n;
    final errors = <String, String>{};
    for (final input in _item.inputs) {
      if ((_answers[input.key] ?? '').trim().isEmpty) {
        errors[input.key] = l10n.galleryWizardRequired;
      }
    }
    if (_needsBot && _botId == null) {
      errors['bot_id'] = l10n.galleryWizardPickBot;
    }
    setState(() {
      _errors = errors;
    });
    return errors.isEmpty;
  }

  Future<void> _install() async {
    if (!_validate()) return;
    setState(() {
      _busy = true;
    });
    final backend = ref.read(backendProvider);
    try {
      final GalleryInstallResult result;
      if (_item.type == 'set') {
        result = await backend.installGallerySet(
          widget.orgId,
          _item.id,
          botId: _botId,
        );
        // Its looks are for this device.
        if (mounted) await applyGallerySetLooks(ref, result);
      } else {
        result = await backend.installGalleryItem(
          widget.orgId,
          _item.type,
          _item.id,
          inputs: _item.inputs.isEmpty
              ? null
              : {for (final i in _item.inputs) i.key: _answers[i.key]!.trim()},
          botId: _needsBot ? _botId : null,
        );
      }
      if (!mounted) return;
      final connected =
          ref.read(connectedAppIdsProvider).value ?? const <String>{};
      setState(() {
        _busy = false;
        _result = result;
        _connected.addAll(connected);
        final needs = result.missingApps.any((a) => !_connected.contains(a.id));
        _step = needs && !result.pending ? _Step.needs : _Step.done;
      });
      // What it became shows in its own list next time it's opened.
      ref.invalidate(skillsProvider);
      ref.invalidate(routinesProvider);
      if (result.installedKind == 'bot' || _item.type == 'set') {
        ref.invalidate(botsProvider);
      }
    } on GalleryInputsInvalid catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errors = e.errors;
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _busy = false;
      });
      showError(context, e, st);
    }
  }

  Future<void> _connect(GalleryMissing app) async {
    final catalog =
        ref.read(appCatalogProvider).value?.apps ?? const <CatalogApp>[];
    final found = catalog.where((c) => c.id == app.id).firstOrNull;
    if (found == null) {
      showMessage(context, context.l10n.galleryWizardConnectInApps(app.name));
      return;
    }
    final integration = await showConnectApp(context, found);
    if (integration != null && mounted) {
      setState(() {
        _connected.add(app.id);
      });
      ref.invalidate(integrationsProvider);
    }
  }

  @override
  Widget build(BuildContext context) => switch (_step) {
    _Step.review => _review(context),
    _Step.needs => _needs(context),
    _Step.done => _done(context),
  };

  Widget _review(BuildContext context) {
    final l10n = context.l10n;
    final access = _item.access;
    final needs = _item.needs;
    final setItems = _item.type == 'set'
        ? gallerySetItems(
            _item,
            ref.watch(galleryCatalogProvider).value?.items ?? const [],
          )
        : const <GalleryItem>[];
    final pickBot = _needsBot || _setWantsBot(setItems);
    final bots = pickBot
        ? ref.watch(botsProvider).value ?? const <Bot>[]
        : const <Bot>[];
    return FormSheet(
      key: const Key('galleryWizardReview'),
      icon: galleryKindIcon(_item.type),
      title: l10n.galleryWizardTitle(_item.name),
      subtitle: _item.description,
      submitLabel: l10n.galleryWizardAdd,
      submitKey: const Key('galleryWizardAdd'),
      busy: _busy,
      onSubmit: _install,
      children: [
        if (setItems.isNotEmpty)
          _Section(
            title: l10n.galleryWizardSetIncludes(setItems.length),
            children: [
              for (final i in setItems)
                Row(
                  children: [
                    GalleryItemIcon(item: i, size: 28),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(child: Text(i.name)),
                    Text(
                      galleryKindName(l10n, i.type),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        if (access != null)
          _Section(
            title: l10n.galleryAccessTitle,
            children: [
              for (final row in galleryAccessRows(l10n, access))
                _Line(icon: row.icon, text: row.text),
            ],
          ),
        if (needs != null && !needs.isEmpty)
          _Section(
            title: l10n.galleryWizardNeeds,
            children: [
              if (needs.skills.isNotEmpty)
                _Line(
                  icon: LucideIcons.sparkles,
                  text: l10n.galleryWizardNeedsSkills(needs.skills.length),
                ),
              if (needs.apps.isNotEmpty)
                _Line(
                  icon: LucideIcons.blocks,
                  text: l10n.galleryWizardNeedsApps(
                    _appNames(needs.apps).join(', '),
                  ),
                ),
            ],
          ),
        if (pickBot)
          DropdownButtonFormField<String>(
            key: const Key('galleryWizardBot'),
            initialValue: _botId,
            decoration: InputDecoration(
              labelText: l10n.galleryWizardBot,
              helperText: _needsBot ? null : l10n.galleryWizardSetBotHelp,
              errorText: _errors['bot_id'],
            ),
            items: [
              for (final b in bots)
                DropdownMenuItem(value: b.id, child: Text(b.name)),
            ],
            onChanged: (v) => setState(() {
              _botId = v;
              _errors = {..._errors}..remove('bot_id');
            }),
          ),
        for (final input in _item.inputs) _field(context, input),
      ],
    );
  }

  List<String> _appNames(List<String> ids) {
    final catalog =
        ref.watch(appCatalogProvider).value?.apps ?? const <CatalogApp>[];
    return [
      for (final id in ids)
        catalog.where((c) => c.id == id).firstOrNull?.name ?? id,
    ];
  }

  Widget _field(BuildContext context, GalleryInput input) {
    final error = _errors[input.key];
    final decoration = InputDecoration(
      labelText: input.label,
      helperText: input.help,
      errorText: error,
    );
    final key = Key('galleryInput-${input.key}');
    switch (input.type) {
      case 'choice':
        final value = _answers[input.key];
        return DropdownButtonFormField<String>(
          key: key,
          initialValue: input.options.contains(value) ? value : null,
          decoration: decoration,
          items: [
            for (final o in input.options)
              DropdownMenuItem(value: o, child: Text(o)),
          ],
          onChanged: (v) => setState(() {
            _answers[input.key] = v ?? '';
          }),
        );
      case 'time':
        final value = _answers[input.key] ?? '';
        return InkWell(
          key: key,
          borderRadius: BorderRadius.circular(AppRadius.tile),
          onTap: () async {
            final parts = value.split(':');
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: int.tryParse(parts.first) ?? 8,
                minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
              ),
            );
            if (picked == null || !mounted) return;
            String two(int n) => n.toString().padLeft(2, '0');
            setState(() {
              _answers[input.key] = '${two(picked.hour)}:${two(picked.minute)}';
            });
          },
          child: InputDecorator(
            decoration: decoration.copyWith(
              suffixIcon: const Icon(LucideIcons.clock, size: 18),
            ),
            child: Text(value.isEmpty ? ' ' : value),
          ),
        );
      default:
        return TextField(
          key: key,
          controller: _controllers[input.key],
          decoration: decoration,
          textInputAction: TextInputAction.next,
        );
    }
  }

  Widget _needs(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      key: const Key('galleryWizardNeedsStep'),
      icon: LucideIcons.plugZap,
      title: l10n.galleryWizardNeedsTitle,
      subtitle: l10n.galleryWizardNeedsHelp(_item.name),
      submitLabel: l10n.galleryWizardContinue,
      submitKey: const Key('galleryWizardContinue'),
      cancelLabel: l10n.galleryWizardSkip,
      onCancel: () => setState(() {
        _step = _Step.done;
      }),
      onSubmit: () => setState(() {
        _step = _Step.done;
      }),
      children: [
        for (final s in _result.missingSkills)
          _NeedRow(
            leading: const Icon(LucideIcons.sparkles, size: 22),
            name: s.name,
            done: true,
            doneLabel: l10n.galleryWizardSkillAdded,
          ),
        for (final a in _result.missingApps)
          _NeedRow(
            key: Key('galleryNeed-${a.id}'),
            leading: AppLogo(appId: a.id, name: a.name, size: 28),
            name: a.name,
            done: _connected.contains(a.id),
            doneLabel: l10n.galleryWizardConnected,
            action: FilledButton.tonal(
              key: Key('galleryConnect-${a.id}'),
              onPressed: () => _connect(a),
              child: Text(l10n.galleryWizardConnect),
            ),
          ),
      ],
    );
  }

  Widget _done(BuildContext context) {
    final l10n = context.l10n;
    final pending = _result.pending;
    final stillMissing = [
      for (final a in _result.missingApps)
        if (!_connected.contains(a.id)) a.name,
    ];
    final notAdded = _result.notAdded;
    final catalog = ref.watch(galleryCatalogProvider).value;
    return FormSheet(
      key: const Key('galleryWizardDone'),
      icon: pending ? LucideIcons.hourglass : LucideIcons.circleCheck,
      title: pending
          ? l10n.galleryWizardPendingTitle
          : l10n.galleryWizardDoneTitle(_item.name),
      subtitle: pending
          ? l10n.galleryWizardPendingHelp
          : stillMissing.isEmpty
          ? l10n.galleryWizardDoneHelp
          : l10n.galleryWizardDoneMissing(stillMissing.join(', ')),
      submitLabel: l10n.doneLabel,
      submitKey: const Key('galleryWizardFinish'),
      showCancel: false,
      onSubmit: () => Navigator.of(context).pop(true),
      children: [
        if (notAdded.isNotEmpty)
          _Section(
            key: const Key('galleryWizardNotAdded'),
            title: l10n.galleryWizardSetNotAdded,
            children: [
              for (final i in notAdded)
                _Line(
                  icon: LucideIcons.circleSlash,
                  text: [
                    catalog?.find(i.type, i.id)?.name ?? i.id,
                    if (i.error case final e? when e.isNotEmpty) e,
                  ].join(' · '),
                ),
            ],
          ),
      ],
    );
  }
}

/// Applies the looks a starter set install handed back (`device`) on this device, in the order
/// the set lists them. Best effort: a look that can't be read is left out.
Future<void> applyGallerySetLooks(
  WidgetRef ref,
  GalleryInstallResult result,
) async {
  final looks = result.deviceItems;
  if (looks.isEmpty) return;
  final backend = ref.read(backendProvider);
  final catalog = ref.read(galleryCatalogProvider).value;
  for (final look in looks) {
    if (!galleryLookKinds.contains(look.type)) continue;
    try {
      var item = catalog?.find(look.type, look.id);
      if (item == null || item.document == null) {
        item = await backend.galleryItem(look.type, look.id);
      }
      await applyGalleryItem(ref, item);
    } catch (_) {
      // Left as it was; the set's other items are in.
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpace.xs,
    children: [
      Text(
        title,
        style: context.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      ...children,
    ],
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: context.colorScheme.onSurfaceVariant),
      const SizedBox(width: AppSpace.sm),
      Expanded(child: Text(text, style: context.textTheme.bodyMedium)),
    ],
  );
}

class _NeedRow extends StatelessWidget {
  const _NeedRow({
    super.key,
    required this.leading,
    required this.name,
    required this.done,
    required this.doneLabel,
    this.action,
  });
  final Widget leading;
  final String name;
  final bool done;
  final String doneLabel;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Row(
      children: [
        SizedBox(width: 32, child: Center(child: leading)),
        const SizedBox(width: AppSpace.sm),
        Expanded(child: Text(name, style: context.textTheme.bodyLarge)),
        if (done)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.check, size: 16, color: scheme.primary),
              const SizedBox(width: 4),
              Text(
                doneLabel,
                style: context.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                ),
              ),
            ],
          )
        else
          ?action,
      ],
    );
  }
}

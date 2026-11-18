import 'package:casama_sdk/casama_sdk.dart' as api show GalleryInput, GalleryInputTypeEnum;
import 'package:casama_sdk/casama_sdk.dart'
    show
        Bot,
        CatalogApp,
        PackInstallResult,
        PackInstallResultStatusEnum,
        PackItemKind,
        PackItemRef,
        PackLookPreview,
        PackPreview,
        PluginServerInfoTypeEnum;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/revealable.dart';
import '../bots/plugins_screen.dart' show PluginPlacePicker, pluginPlacesProvider;
import '../integrations/app_logo.dart';
import '../integrations/connect_app_sheet.dart';
import '../settings/gallery_looks.dart';
import 'pack_logic.dart';
import 'pack_parts.dart';

/// Walks the person through adding a pack (docs/PLUGINS-AND-PACKS-PLAN.md C): what's inside with
/// a checkbox each, its questions, the keys and settings its tools need, what it can reach, a bot
/// when it brings none, then what happened to each item, apps to connect and looks to use.
/// Returns true once something was added (or is waiting for an admin).
Future<bool> showPackInstall(
  BuildContext context,
  WidgetRef ref, {
  required PackPreview preview,
  required PackFrom from,
}) async {
  final org = ref.read(currentOrgProvider);
  if (org == null) return false;
  final ok = await showAdaptiveSheet<bool>(
    context: context,
    dialogMaxWidth: 600,
    builder: (_) => PackInstallWizard(preview: preview, from: from, orgId: org.id),
  );
  return ok ?? false;
}

enum PackStep { inside, questions, secrets, reach, bot, result }

class PackInstallWizard extends ConsumerStatefulWidget {
  const PackInstallWizard({super.key, required this.preview, required this.from, required this.orgId});
  final PackPreview preview;
  final PackFrom from;
  final String orgId;

  @override
  ConsumerState<PackInstallWizard> createState() => _PackInstallWizardState();
}

class _PackInstallWizardState extends ConsumerState<PackInstallWizard> {
  var _step = PackStep.inside;
  var _busy = false;

  /// Unticked items, by `kind:id`.
  final _skip = <String>{};
  final _answers = <String, String>{};
  final _inputControllers = <String, TextEditingController>{};
  final _secrets = <String, TextEditingController>{};
  final _settings = <String, TextEditingController>{};
  var _errors = <String, String>{};
  String? _botId;
  // Where the pack's plugin tools run (D-344): null is each bot's computer.
  String? _deviceId;
  PackInstallResult? _result;

  /// `pack_installed`: the server's words.
  String? _alreadyHere;
  final _connected = <String>{};
  final _usedLooks = <String>{};

  PackPreview get _p => widget.preview;

  @override
  void initState() {
    super.initState();
    for (final input in _p.inputs) {
      final value = input.default_ ?? '';
      _answers[input.key] = value;
      if (input.type == api.GalleryInputTypeEnum.text || input.type == api.GalleryInputTypeEnum.timezone) {
        _inputControllers[input.key] = TextEditingController(text: value)
          ..addListener(() => _answers[input.key] = _inputControllers[input.key]!.text);
      }
      if (input.type == api.GalleryInputTypeEnum.timezone && value.isEmpty) _fillTimezone(input.key);
    }
    for (final s in _p.secrets) {
      _secrets[s.name] = TextEditingController()..addListener(_refresh);
    }
    for (final s in _p.settings) {
      _settings[s.name] = TextEditingController(text: s.default_ ?? '');
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _fillTimezone(String key) async {
    try {
      final tz = (await FlutterTimezone.getLocalTimezone()).identifier;
      if (mounted && (_inputControllers[key]?.text.isEmpty ?? false)) _inputControllers[key]!.text = tz;
    } catch (_) {
      // Left for the person to type.
    }
  }

  @override
  void dispose() {
    for (final c in [..._inputControllers.values, ..._secrets.values, ..._settings.values]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _on(PackItemKind kind, String id) => !_skip.contains('${kind.value}:$id');

  bool get _toolsOn => _p.servers.isNotEmpty && _on(PackItemKind.tools, 'tools');

  /// Routines or tools go to a bot: the pack's own, else one the person picks.
  bool get _needsBot {
    final ownBot = _p.bots.any((b) => _on(PackItemKind.bot, b.id));
    final routines = _p.routines.any((r) => _on(PackItemKind.routine, r.id));
    return !ownBot && (routines || _toolsOn);
  }

  List<PackStep> get _steps => [
    PackStep.inside,
    if (_p.inputs.isNotEmpty) PackStep.questions,
    if (_toolsOn && (_p.secrets.isNotEmpty || _p.settings.isNotEmpty)) PackStep.secrets,
    PackStep.reach,
    if (_needsBot) PackStep.bot,
  ];

  bool get _somethingTicked => packEntries(context, _p).values.expand((e) => e).any((e) => !_skip.contains(e.key));

  bool _validate() {
    final l10n = context.l10n;
    final errors = <String, String>{};
    switch (_step) {
      case PackStep.questions:
        for (final input in _p.inputs) {
          if ((_answers[input.key] ?? '').trim().isEmpty) errors[input.key] = l10n.galleryWizardRequired;
        }
      case PackStep.secrets:
        for (final e in _secrets.entries) {
          if (e.value.text.trim().isEmpty) errors['secret:${e.key}'] = l10n.galleryWizardRequired;
        }
      case PackStep.bot:
        final bots = ref.read(botsProvider).value ?? const <Bot>[];
        if (_botId == null && bots.isNotEmpty) errors['bot_id'] = l10n.galleryWizardPickBot;
      default:
        break;
    }
    setState(() => _errors = errors);
    return errors.isEmpty;
  }

  void _next() {
    if (!_validate()) return;
    final steps = _steps;
    final i = steps.indexOf(_step);
    if (i == steps.length - 1) {
      _install();
    } else {
      setState(() => _step = steps[i + 1]);
    }
  }

  void _back() {
    final steps = _steps;
    final i = steps.indexOf(_step);
    if (i <= 0) {
      Navigator.of(context).pop(false);
    } else {
      setState(() {
        _errors = {};
        _step = steps[i - 1];
      });
    }
  }

  List<PackItemRef> _skipRefs() => [
    for (final key in _skip)
      PackItemRef(
        kind: PackItemKind.values.firstWhere((k) => key.startsWith('${k.value}:')),
        id: key.substring(key.indexOf(':') + 1),
      ),
  ];

  Future<void> _install() async {
    setState(() => _busy = true);
    final backend = ref.read(backendProvider);
    try {
      final result = await backend.installPack(
        widget.orgId,
        widget.from.pinned(_p.commit),
        skip: _skipRefs(),
        inputs: _p.inputs.isEmpty ? null : {for (final i in _p.inputs) i.key: (_answers[i.key] ?? '').trim()},
        secrets: _toolsOn ? {for (final e in _secrets.entries) e.key: e.value.text.trim()} : null,
        settings: _toolsOn
            ? {
                for (final e in _settings.entries)
                  if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
              }
            : null,
        botId: _needsBot ? _botId : null,
        deviceId: _toolsOn ? _deviceId : null,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _result = result;
        _step = PackStep.result;
      });
      // What it made shows in its own lists next time they're opened.
      ref.invalidate(botsProvider);
      ref.invalidate(skillsProvider);
      ref.invalidate(routinesProvider);
      ref.invalidate(appCatalogProvider);
      ref.invalidate(installedPacksProvider);
    } on GalleryInputsInvalid catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errors = e.errors;
        if (_p.inputs.isNotEmpty) _step = PackStep.questions;
      });
    } on PackError catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (e.code == 'pack_installed') {
        setState(() {
          _alreadyHere = e.message;
          _step = PackStep.result;
        });
      } else {
        showError(context, e);
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _busy = false);
      showError(context, e, st);
    }
  }

  Future<void> _connect(String id, String name) async {
    var catalog = ref.read(appCatalogProvider).value?.apps ?? const <CatalogApp>[];
    var found = catalog.where((c) => c.id == id).firstOrNull;
    if (found == null) {
      // The pack's own apps join the catalog once installed.
      try {
        catalog = (await ref.read(appCatalogProvider.future)).apps;
        found = catalog.where((c) => c.id == id).firstOrNull;
      } catch (_) {}
    }
    if (!mounted) return;
    if (found == null) {
      showMessage(context, context.l10n.galleryWizardConnectInApps(name));
      return;
    }
    final integration = await showConnectApp(context, found);
    if (integration != null && mounted) {
      setState(() => _connected.add(id));
      ref.invalidate(integrationsProvider);
    }
  }

  Future<void> _useLook(PackLookPreview look) async {
    final done = await runGuarded<bool>(context, () async {
      await applyGalleryItem(
        ref,
        GalleryItem(
          id: look.id,
          type: look.type.value,
          name: look.name,
          authorName: '',
          license: '',
          document: look.document,
        ),
      );
      return true;
    });
    if (done == true && mounted) setState(() => _usedLooks.add('${look.type.value}/${look.id}'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_step == PackStep.result) return _resultStep(context);
    final steps = _steps;
    final last = steps.indexOf(_step) == steps.length - 1;
    final (IconData icon, String title, String? subtitle, List<Widget> children) = switch (_step) {
      PackStep.inside => (
        packIcon(_p.icon),
        l10n.packWizardTitle(_p.title),
        l10n.packWhatsInsideHelp,
        [
          PackContentsList(
            preview: _p,
            skipped: _skip,
            onToggle: (e, on) => setState(() => on ? _skip.remove(e.key) : _skip.add(e.key)),
          ),
          if (!_somethingTicked) FormNote(l10n.packNothingTicked),
        ],
      ),
      PackStep.questions => (
        LucideIcons.messageCircleQuestion,
        l10n.packQuestions,
        l10n.packQuestionsHelp,
        [for (final input in _p.inputs) _field(context, input)],
      ),
      PackStep.secrets => (LucideIcons.keyRound, l10n.packSecretsTitle, l10n.packSecretsHelp, _secretFields(context)),
      PackStep.reach => (
        LucideIcons.shieldCheck,
        l10n.packReachTitle,
        null,
        [
          PackReachCard(reach: _p.reach, reviewed: _p.reviewed, warnings: _p.warnings),
          if (_toolsOn && _p.servers.any((s) => s.type == PluginServerInfoTypeEnum.stdio))
            PluginPlacePicker(
              places: ref.watch(pluginPlacesProvider(widget.orgId)).value ?? const [],
              selected: _deviceId,
              enabled: !_busy,
              onChanged: (id) => setState(() => _deviceId = id),
            ),
        ],
      ),
      PackStep.bot => (LucideIcons.bot, l10n.packPickBotTitle, l10n.packPickBotHelp, [_botPicker(context)]),
      PackStep.result => throw StateError('unreachable'),
    };
    return FormSheet(
      key: Key('packStep-${_step.name}'),
      icon: icon,
      title: title,
      subtitle: subtitle,
      submitLabel: last ? l10n.packAdd : l10n.next,
      submitKey: const Key('packNext'),
      cancelLabel: _step == PackStep.inside ? null : l10n.sharePackGoBack,
      onCancel: _back,
      busy: _busy,
      onSubmit: _busy || !_somethingTicked ? null : _next,
      children: children,
    );
  }

  List<Widget> _secretFields(BuildContext context) => [
    for (final s in _p.secrets)
      Revealable(
        builder: (context, hidden, toggle) => TextField(
          key: Key('packSecret-${s.name}'),
          controller: _secrets[s.name],
          obscureText: hidden,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: s.name,
            helperText: s.description.isEmpty ? null : s.description,
            errorText: _errors['secret:${s.name}'],
            suffixIcon: toggle,
          ),
        ),
      ),
    for (final s in _p.settings)
      TextField(
        key: Key('packSetting-${s.name}'),
        controller: _settings[s.name],
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: s.label.isEmpty ? s.name : s.label,
          helperText: s.description.isEmpty ? null : s.description,
        ),
      ),
  ];

  Widget _botPicker(BuildContext context) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    return DropdownButtonFormField<String>(
      key: const Key('packBot'),
      initialValue: _botId,
      decoration: InputDecoration(labelText: l10n.galleryWizardBot, errorText: _errors['bot_id']),
      items: [for (final b in bots) DropdownMenuItem(value: b.id, child: Text(b.name))],
      onChanged: (v) => setState(() {
        _botId = v;
        _errors = {..._errors}..remove('bot_id');
      }),
    );
  }

  Widget _field(BuildContext context, api.GalleryInput input) {
    final decoration = InputDecoration(labelText: input.label, helperText: input.help, errorText: _errors[input.key]);
    final key = Key('packInput-${input.key}');
    switch (input.type) {
      case api.GalleryInputTypeEnum.choice:
        final options = input.options ?? const <String>[];
        final value = _answers[input.key];
        return DropdownButtonFormField<String>(
          key: key,
          initialValue: options.contains(value) ? value : null,
          decoration: decoration,
          items: [for (final o in options) DropdownMenuItem(value: o, child: Text(o))],
          onChanged: (v) => setState(() => _answers[input.key] = v ?? ''),
        );
      case api.GalleryInputTypeEnum.time:
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
            setState(() => _answers[input.key] = '${two(picked.hour)}:${two(picked.minute)}');
          },
          child: InputDecorator(
            decoration: decoration.copyWith(suffixIcon: const Icon(LucideIcons.clock, size: 18)),
            child: Text(value.isEmpty ? ' ' : value),
          ),
        );
      default:
        return TextField(
          key: key,
          controller: _inputControllers[input.key],
          decoration: decoration,
          textInputAction: TextInputAction.next,
        );
    }
  }

  Widget _resultStep(BuildContext context) {
    final l10n = context.l10n;
    final router = GoRouter.maybeOf(context);
    if (_alreadyHere case final message?) {
      return FormSheet(
        key: const Key('packAlreadyInstalled'),
        icon: LucideIcons.packageCheck,
        title: l10n.packInstalledTitle,
        subtitle: message,
        submitLabel: l10n.packOpenInstalled,
        submitKey: const Key('packOpenInstalled'),
        onSubmit: () {
          Navigator.of(context).pop(false);
          router?.push('/settings/gallery/packs');
        },
        children: const [],
      );
    }
    final r = _result!;
    final pending = r.status == PackInstallResultStatusEnum.approvalPending;
    return FormSheet(
      key: const Key('packResult'),
      icon: pending ? LucideIcons.hourglass : LucideIcons.circleCheck,
      title: pending ? l10n.galleryWizardPendingTitle : l10n.packDoneTitle(_p.title),
      subtitle: pending ? l10n.packPendingHelp : l10n.packDoneHelp,
      submitLabel: l10n.doneLabel,
      submitKey: const Key('packFinish'),
      showCancel: false,
      onSubmit: () => Navigator.of(context).pop(true),
      children: [
        if (r.items.isNotEmpty)
          GroupedCard(
            key: const Key('packResultItems'),
            children: [
              for (final i in r.items)
                GroupedTile(
                  key: Key('packResult-${i.kind.value}:${i.id}'),
                  icon: packKindIcon(i.kind),
                  title: i.name,
                  subtitle: [
                    packStatusLabel(l10n, i.status),
                    if (i.error case final e? when e.isNotEmpty) e,
                  ].join(' · '),
                ),
            ],
          ),
        if (!pending && r.missing.apps.isNotEmpty) ...[
          SectionHeader(title: l10n.packConnectTitle),
          Text(l10n.packConnectHelp, style: context.textTheme.bodySmall),
          GroupedCard(
            children: [
              for (final a in r.missing.apps)
                GroupedTile(
                  key: Key('packNeed-${a.id}'),
                  icon: LucideIcons.blocks,
                  leading: AppLogo(appId: a.id, name: a.name, size: 28),
                  title: a.name,
                  trailing: _connected.contains(a.id)
                      ? Text(l10n.galleryWizardConnected, style: TextStyle(color: context.colorScheme.primary))
                      : FilledButton.tonal(
                          key: Key('packConnect-${a.id}'),
                          onPressed: () => _connect(a.id, a.name),
                          child: Text(l10n.galleryWizardConnect),
                        ),
                ),
            ],
          ),
        ],
        if (!pending && r.looks.isNotEmpty) ...[
          SectionHeader(title: l10n.packLooksTitle),
          GroupedCard(
            children: [
              for (final k in r.looks)
                GroupedTile(
                  key: Key('packLook-${k.type.value}/${k.id}'),
                  icon: LucideIcons.palette,
                  title: k.name,
                  trailing: _usedLooks.contains('${k.type.value}/${k.id}')
                      ? Text(l10n.packLookInUse, style: TextStyle(color: context.colorScheme.primary))
                      : FilledButton.tonal(
                          key: Key('packUseLook-${k.type.value}/${k.id}'),
                          onPressed: () => _useLook(k),
                          child: Text(l10n.packUseLook),
                        ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import 'companion.dart';
import 'companion_controller.dart';

/// One coding agent the server knows (D-370), or the app's own fallback for older servers.
class ScannedAgent {
  const ScannedAgent({
    required this.id,
    required this.label,
    required this.bin,
    required this.preallowed,
  });
  final String id;
  final String label;
  final String bin;

  /// Runs whenever commands are on; any other agent needs one Allow on this computer.
  final bool preallowed;
}

/// What the Coding Agents section shows: the server's agents, the person's own ones on this
/// computer, and which commands this computer has.
class CodingAgentsScan {
  const CodingAgentsScan({
    required this.catalog,
    required this.own,
    required this.found,
  });
  final List<ScannedAgent> catalog;

  /// Null when the server has no own agents (older than D-371).
  final List<OwnCodingAgentEntry>? own;
  final Set<String> found;

  List<ScannedAgent> get installed => [
    for (final a in catalog)
      if (found.contains(a.bin)) a,
  ];
}

/// The catalog from the server, falling back to the agents this app knows when the server is older
/// or can't be reached; ids this app has never heard of are shown like any other.
final codingAgentsScanProvider = FutureProvider.autoDispose
    .family<CodingAgentsScan, String>((ref, deviceId) async {
      final backend = ref.read(backendProvider);
      final fallback = [
        for (final a in builtInCodingAgents)
          ScannedAgent(id: a.id, label: a.label, bin: a.bin, preallowed: true),
      ];
      List<ScannedAgent> catalog;
      try {
        final list = await backend.codingAgents();
        catalog = list == null || list.isEmpty
            ? fallback
            : [
                for (final a in list)
                  if (isAgentBin(a.bin))
                    ScannedAgent(
                      id: a.id,
                      label: a.label,
                      bin: a.bin,
                      preallowed: a.preallowed,
                    ),
              ];
      } catch (_) {
        catalog = fallback;
      }
      List<OwnCodingAgentEntry>? own;
      try {
        own = await backend.ownCodingAgents(deviceId);
      } catch (_) {
        own = null;
      }
      final bins = {
        for (final a in catalog) a.bin,
        for (final a in own ?? const <OwnCodingAgentEntry>[]) a.bin,
      };
      final found = await ref
          .read(companionProvider)
          .detectCodingAgents(bins: bins);
      return CodingAgentsScan(catalog: catalog, own: own, found: found.toSet());
    });

/// Coding agents on this computer (D-097): the catalog's agents it has, one Allow for new ones
/// (D-370), and the person's own agents (D-371).
class CodingAgentsSection extends ConsumerWidget {
  const CodingAgentsSection({
    super.key,
    required this.device,
    required this.shellOn,
    required this.onAllow,
  });
  final LocalDevice device;
  final bool shellOn;

  /// Turns on Run commands.
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = codingAgentsScanProvider(device.id);
    final scan = ref.watch(provider);
    final checking = scan.isLoading;
    final data = scan.value;
    final installed = data?.installed ?? const <ScannedAgent>[];
    final own = data?.own ?? const <OwnCodingAgentEntry>[];
    final allowed = device.allowedCodingAgents ?? const <String>[];
    final controller = ref.read(companionControllerProvider.notifier);
    final scheme = context.colorScheme;
    final needsAllow = installed.any(
      (a) => !a.preallowed && !allowed.contains(a.id),
    );
    final any = installed.isNotEmpty || own.isNotEmpty;

    Future<void> saveOwn(List<OwnCodingAgent> agents) async {
      await ref.read(backendProvider).setOwnCodingAgents(device.id, agents);
      ref.invalidate(provider);
    }

    OwnCodingAgent plain(OwnCodingAgentEntry a) => OwnCodingAgent(
      key: a.key,
      label: a.label,
      bin: a.bin,
      command: a.command,
      result: a.result,
      timeoutMin: a.timeoutMin,
    );

    Future<void> edit(OwnCodingAgentEntry? current) async {
      final saved = await showAdaptiveSheet<OwnCodingAgent>(
        context: context,
        builder: (_) => OwnAgentForm(
          deviceId: device.id,
          initial: current == null ? null : plain(current),
          taken: {
            for (final a in own)
              if (a.key != current?.key) a.key,
          },
        ),
      );
      if (saved == null || !context.mounted) return;
      await runGuarded(
        context,
        () => saveOwn([
          for (final a in own)
            if (a.key != saved.key) plain(a),
          saved,
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.codingAgents,
          // Installed one after opening this page? Look again without restarting the app.
          trailing: TextButton.icon(
            key: const Key('refreshCodingAgents'),
            onPressed: checking
                ? null
                : () async {
                    ref.invalidate(provider);
                    final s = await ref.read(provider.future);
                    final n =
                        s.installed.length +
                        (s.own ?? const [])
                            .where((a) => s.found.contains(a.bin))
                            .length;
                    if (context.mounted) {
                      showSuccess(context, l10n.codingAgentsFound(n));
                    }
                  },
            icon: checking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.refreshCw, size: 16),
            label: Text(l10n.refresh),
          ),
        ),
        if (!any)
          AppCard(
            child: FormNote(l10n.codingAgentsNone, icon: LucideIcons.codeXml),
          )
        else
          GroupedCard(
            children: [
              for (final a in installed)
                GroupedTile(
                  key: Key('codingAgent-${a.bin}'),
                  icon: LucideIcons.codeXml,
                  title: a.label,
                  subtitle: a.bin,
                  trailing: a.preallowed
                      ? null
                      : allowed.contains(a.id)
                      ? StatusLabel(
                          text: l10n.codingAgentAllowed,
                          color: context.appColors.working,
                          icon: LucideIcons.check,
                        )
                      : TextButton(
                          key: Key('allowAgent-${a.id}'),
                          onPressed: () => runGuarded(
                            context,
                            () => controller.allowCodingAgent(a.id),
                          ),
                          child: Text(l10n.codingAgentAllow),
                        ),
                ),
              for (final a in own)
                GroupedTile(
                  key: Key('ownAgent-${a.key}'),
                  icon: LucideIcons.squareTerminal,
                  title: a.label,
                  subtitle: data!.found.contains(a.bin)
                      ? a.command
                      : l10n.ownAgentNotFound,
                  onTap: () => edit(a),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusLabel(
                        text: l10n.ownAgentYours,
                        color: scheme.primary,
                        pill: true,
                      ),
                      IconButton(
                        key: Key('deleteOwnAgent-${a.key}'),
                        tooltip: l10n.delete,
                        icon: Icon(
                          LucideIcons.x,
                          color: scheme.onSurfaceVariant,
                        ),
                        onPressed: () => runGuarded(
                          context,
                          () => saveOwn([
                            for (final o in own)
                              if (o.key != a.key) plain(o),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        if (any && !shellOn)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Row(
              children: [
                Expanded(child: FormNote(l10n.codingAgentsNeedShell)),
                TextButton(
                  key: const Key('allowCodingAgents'),
                  onPressed: onAllow,
                  child: Text(l10n.allowCommands),
                ),
              ],
            ),
          )
        else if (any) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: FormNote(l10n.codingAgentsHelp),
          ),
          if (needsAllow)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: FormNote(l10n.codingAgentsAllowHelp),
            ),
        ],
        if (own.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: FormNote(l10n.ownAgentsHelp, icon: LucideIcons.lock),
          ),
        // Only on servers that keep own agents (D-371).
        if (data?.own != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('addOwnAgent'),
              onPressed: own.length >= 20 ? null : () => edit(null),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(l10n.ownAgentsAdd),
            ),
          ),
      ],
    );
  }
}

/// A key for an own agent from its name: lower case letters, digits and underscores.
String ownAgentKey(String label, Iterable<String> taken) {
  var base = label
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  if (base.isEmpty || !RegExp('^[a-z]').hasMatch(base)) base = 'agent_$base';
  base = base.length > 20 ? base.substring(0, 20) : base;
  var key = base;
  for (var i = 2; taken.contains(key); i++) {
    key = '${base}_$i';
  }
  return key;
}

/// Add or edit one of the person's own agents, with a Test run on this computer (D-371).
class OwnAgentForm extends ConsumerStatefulWidget {
  const OwnAgentForm({
    super.key,
    required this.deviceId,
    required this.taken,
    this.initial,
  });
  final String deviceId;
  final Set<String> taken;
  final OwnCodingAgent? initial;

  @override
  ConsumerState<OwnAgentForm> createState() => _OwnAgentFormState();
}

class _OwnAgentFormState extends ConsumerState<OwnAgentForm> {
  late final _label = TextEditingController(text: widget.initial?.label);
  late final _bin = TextEditingController(text: widget.initial?.bin);
  late final _command = TextEditingController(text: widget.initial?.command);
  late final _field = TextEditingController(
    text: _fieldOf(widget.initial?.result) ?? 'response',
  );
  late final _timeout = TextEditingController(
    text: '${widget.initial?.timeoutMin ?? 30}',
  );
  late String _result = _modeOf(widget.initial?.result);
  String? _error;
  bool _testing = false;
  CodingAgentTestResult? _test;

  static String _modeOf(String? r) =>
      r == null ? 'tail' : (r.startsWith('json_field:') ? 'json_field' : r);
  static String? _fieldOf(String? r) => r != null && r.startsWith('json_field:')
      ? r.substring('json_field:'.length)
      : null;

  @override
  void dispose() {
    for (final c in [_label, _bin, _command, _field, _timeout]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _resultValue =>
      _result == 'json_field' ? 'json_field:${_field.text.trim()}' : _result;

  /// What's filled in, when it's complete enough to test or save.
  OwnCodingAgent? _draft() {
    final label = _label.text.trim();
    final bin = _bin.text.trim();
    final command = _command.text.trim();
    final minutes = int.tryParse(_timeout.text.trim()) ?? 30;
    if (label.isEmpty || !isAgentBin(bin) || !command.contains('{task}')) {
      setState(() => _error = context.l10n.ownAgentBadCommand('{task}'));
      return null;
    }
    setState(() => _error = null);
    return OwnCodingAgent(
      key: widget.initial?.key ?? ownAgentKey(label, widget.taken),
      label: label,
      bin: bin,
      command: command,
      result: _resultValue,
      timeoutMin: minutes.clamp(1, 120),
    );
  }

  Future<void> _runTest() async {
    final d = _draft();
    if (d == null) return;
    setState(() {
      _testing = true;
      _test = null;
    });
    final r = await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .testOwnCodingAgent(
            widget.deviceId,
            TestOwnCodingAgentRequest(
              label: d.label,
              bin: d.bin,
              command: d.command,
              result: d.result,
            ),
          ),
    );
    if (!mounted) return;
    setState(() {
      _testing = false;
      _test = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final test = _test;
    final colors = context.appColors;
    return FormSheet(
      icon: LucideIcons.squareTerminal,
      title: widget.initial == null
          ? l10n.ownAgentFormTitle
          : l10n.ownAgentEditTitle,
      submitLabel: l10n.save,
      submitKey: const Key('saveOwnAgent'),
      onSubmit: () {
        final d = _draft();
        if (d != null) Navigator.pop(context, d);
      },
      children: [
        TextField(
          key: const Key('ownAgentLabel'),
          controller: _label,
          decoration: InputDecoration(
            labelText: l10n.ownAgentName,
            hintText: 'Aider',
          ),
        ),
        TextField(
          key: const Key('ownAgentBin'),
          controller: _bin,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: l10n.ownAgentBin,
            hintText: 'aider',
          ),
        ),
        TextField(
          key: const Key('ownAgentCommand'),
          controller: _command,
          autocorrect: false,
          enableSuggestions: false,
          minLines: 1,
          maxLines: 3,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontFamilyFallback: ['Menlo', 'Courier'],
          ),
          decoration: InputDecoration(
            labelText: l10n.ownAgentCommand,
            hintText: 'aider --message {task} --yes',
          ),
        ),
        FormNote(
          l10n.ownAgentCommandHelp('{task}', '{folder}', '{result_file}'),
        ),
        DropdownButtonFormField<String>(
          key: const Key('ownAgentResult'),
          initialValue: _result,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.ownAgentResult),
          items: [
            DropdownMenuItem(
              value: 'tail',
              child: Text(l10n.ownAgentResultTail),
            ),
            DropdownMenuItem(
              value: 'json_result',
              child: Text(l10n.ownAgentResultJson),
            ),
            DropdownMenuItem(
              value: 'stream_json',
              child: Text(l10n.ownAgentResultStream),
            ),
            DropdownMenuItem(
              value: 'json_field',
              child: Text(l10n.ownAgentResultField),
            ),
            DropdownMenuItem(
              value: 'marker',
              child: Text(l10n.ownAgentResultFile),
            ),
          ],
          onChanged: (v) => setState(() => _result = v ?? 'tail'),
        ),
        if (_result == 'json_field')
          TextField(
            key: const Key('ownAgentField'),
            controller: _field,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.ownAgentResultFieldName,
            ),
          ),
        TextField(
          key: const Key('ownAgentTimeout'),
          controller: _timeout,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.ownAgentTimeLimit),
        ),
        Row(
          children: [
            OutlinedButton.icon(
              key: const Key('testOwnAgent'),
              onPressed: _testing ? null : _runTest,
              icon: _testing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.play, size: 16),
              label: Text(l10n.ownAgentTest),
            ),
            const SizedBox(width: 12),
            Expanded(child: FormNote(l10n.ownAgentTestHelp)),
          ],
        ),
        if (test != null) ...[
          FormNote(
            key: const Key('ownAgentTestResult'),
            test.ok
                ? l10n.ownAgentTestPassed(test.reply)
                : test.timedOut
                ? l10n.ownAgentTestTimedOut
                : l10n.ownAgentTestFailed(test.exitCode),
            icon: test.ok ? LucideIcons.circleCheck : LucideIcons.circleAlert,
            color: test.ok ? colors.working : colors.negative,
          ),
          if (test.output.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 160),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  test.output,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontFamilyFallback: ['Menlo', 'Courier'],
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
        if (_error != null)
          FormNote(
            _error!,
            icon: LucideIcons.circleAlert,
            color: colors.negative,
          ),
      ],
    );
  }
}

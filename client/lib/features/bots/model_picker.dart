import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../ui/adaptive_modal.dart';

/// A dropdown-style field for a bot's model. Opens a searchable list of the models the chosen key
/// can use (recommended first) and still accepts any model id typed in.
class ModelPickerField extends ConsumerWidget {
  const ModelPickerField({super.key, required this.credentialId, required this.value, required this.onChanged});
  final String? credentialId;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = credentialId == null ? null : ref.watch(modelOptionsProvider(credentialId!)).value;
    ModelOption? selected;
    for (final m in list?.items ?? const <ModelOption>[]) {
      if (m.id == value) selected = m;
    }
    final enabled = credentialId != null;
    return InkWell(
      key: const Key('modelPicker'),
      borderRadius: BorderRadius.circular(4),
      onTap: !enabled
          ? null
          : () async {
              final picked = await showAdaptiveSheet<String>(
                context: context,
                heightFactor: 0.85,
                builder: (_) => _ModelSheet(credentialId: credentialId!, current: value),
              );
              if (picked != null) onChanged(picked);
            },
      child: InputDecorator(
        isEmpty: value.isEmpty,
        decoration: InputDecoration(
          labelText: l10n.model,
          enabled: enabled,
          prefixIcon: const Icon(Icons.auto_awesome_outlined, size: 20),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: value.isEmpty
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(selected?.name ?? value, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (selected != null && selected.name != value)
                    Text(value, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
      ),
    );
  }
}

class _ModelSheet extends ConsumerStatefulWidget {
  const _ModelSheet({required this.credentialId, required this.current});
  final String credentialId;
  final String current;

  @override
  ConsumerState<_ModelSheet> createState() => _ModelSheetState();
}

class _ModelSheetState extends ConsumerState<_ModelSheet> {
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(ModelOption m) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return m.id.toLowerCase().contains(q) || m.name.toLowerCase().contains(q);
  }

  String _context(int? tokens) {
    if (tokens == null) return '';
    if (tokens >= 1000000) return '${(tokens / 1000000).toStringAsFixed(tokens % 1000000 == 0 ? 0 : 1)}M context';
    return '${(tokens / 1000).round()}K context';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(modelOptionsProvider(widget.credentialId));
    final typed = _query.trim();
    Widget tile(ModelOption m) => ListTile(
      key: Key('model-${m.id}'),
      title: Text(m.name),
      subtitle: Text([m.id, _context(m.contextLength)].where((s) => s.isNotEmpty).join(' · ')),
      trailing: m.id == widget.current ? const Icon(Icons.check) : null,
      onTap: () => Navigator.of(context).pop(m.id),
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.chooseModel, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              TextField(
                key: const Key('modelSearch'),
                controller: _search,
                autofocus: true,
                autocorrect: false,
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l10n.searchModels),
                onChanged: (v) => setState(() => _query = v),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) Navigator.of(context).pop(v.trim());
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncView(
            value: async,
            onRetry: () => ref.invalidate(modelOptionsProvider(widget.credentialId)),
            data: (list) {
              final featured = list.items.where((m) => m.featured == true && _matches(m)).toList();
              final rest = list.items.where((m) => m.featured != true && _matches(m)).toList();
              final exact = list.items.any((m) => m.id == typed);
              // Built lazily: OpenRouter alone lists several hundred models.
              final rows = <Widget Function()>[
                if (list.source_ == ModelOptionListSource_Enum.featured)
                  () => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(l10n.modelListFallback(list.error ?? ''), style: Theme.of(context).textTheme.bodySmall),
                  ),
                if (typed.isNotEmpty && !exact)
                  () => ListTile(
                    key: const Key('customModel'),
                    leading: const Icon(Icons.edit),
                    title: Text(l10n.useCustomModel(typed)),
                    onTap: () => Navigator.of(context).pop(typed),
                  ),
                if (featured.isNotEmpty) () => _Header(l10n.recommendedModels),
                for (final m in featured) () => tile(m),
                if (rest.isNotEmpty) () => _Header(l10n.allModels),
                for (final m in rest) () => tile(m),
                if (featured.isEmpty && rest.isEmpty && typed.isEmpty) () => Padding(padding: const EdgeInsets.all(16), child: Text(l10n.noModelsFound)),
              ];
              return ListView.builder(itemCount: rows.length, itemBuilder: (_, i) => rows[i]());
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
  );
}

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/billing.dart';
import '../../core/display_text.dart';
import '../../core/providers.dart';
import '../settings/model_keys_screen.dart';
import '../../core/widgets.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/bottom_padding.dart';

/// The model Casama Cloud runs. Null on a self-hosted server, where the person chooses.
String? casamaLockedModel(
  WidgetRef ref,
  String? credentialId, {
  bool listen = true,
}) {
  final billing = listen
      ? ref.watch(billingProvider).value
      : ref.read(billingProvider).value;
  if (billing?.enabled != true) return null;
  final backend = listen
      ? ref.watch(backendProvider)
      : ref.read(backendProvider);
  return backend.defaultModelFor('openrouter');
}

/// True on Casama Cloud (billing on), where Casama chooses every model (D-188). The key and model
/// fields are not shown there at all: there is nothing for a person to choose.
bool casamaModelFixed(WidgetRef ref, {bool listen = true}) =>
    (listen ? ref.watch(billingProvider) : ref.read(billingProvider)).value?.enabled == true;

/// On Casama Cloud the bot uses Casama's own key; elsewhere the first usable key.
String? preferredKeyId(WidgetRef ref, List<Credential> keys, {bool listen = true}) {
  if (keys.isEmpty) return null;
  if (casamaModelFixed(ref, listen: listen)) {
    for (final k in keys) {
      if (k.id == casamaCloudCredentialId) return k.id;
    }
  }
  return keys.first.id;
}

/// A dropdown-style field for a bot's model. Opens a searchable list of the models the chosen key
/// can use (recommended first) and still accepts any model id typed in. On Casama Cloud the
/// model is fixed: the field shows what Casama runs and does not open.
class ModelPickerField extends ConsumerWidget {
  const ModelPickerField({
    super.key,
    required this.credentialId,
    required this.value,
    required this.onChanged,
  });
  final String? credentialId;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locked = casamaLockedModel(ref, credentialId);
    final shown = locked ?? value;
    final list = credentialId == null
        ? null
        : ref.watch(modelOptionsProvider(credentialId!)).value;
    ModelOption? selected;
    for (final m in list?.items ?? const <ModelOption>[]) {
      if (m.id == shown) selected = m;
    }
    final enabled = credentialId != null;
    return InkWell(
      key: const Key('modelPicker'),
      borderRadius: BorderRadius.circular(4),
      onTap: !enabled || locked != null
          ? null
          : () async {
              final picked = await showAdaptiveSheet<String>(
                context: context,
                heightFactor: 0.85,
                contentPadsBottom: true,
                builder: (_) =>
                    _ModelSheet(credentialId: credentialId!, current: shown),
              );
              if (picked != null) onChanged(picked);
            },
      child: InputDecorator(
        isEmpty: shown.isEmpty,
        decoration: InputDecoration(
          labelText: l10n.model,
          enabled: enabled,
          helperText: locked == null ? null : l10n.casamaCloudModelLocked,
          prefixIcon: const Icon(LucideIcons.sparkles, size: 20),
          suffixIcon: Icon(
            locked == null ? LucideIcons.chevronDown : LucideIcons.lock,
          ),
        ),
        // The friendly name only; the raw id shows only when the list doesn't know it (D-182).
        child: shown.isEmpty
            ? null
            : Text(
                selected?.name ?? shown,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  /// Search still matches the model's id, though rows show only its name.
  bool _matches(ModelOption m) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return m.id.toLowerCase().contains(q) || m.name.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(modelOptionsProvider(widget.credentialId));
    final cloud = widget.credentialId == casamaCloudCredentialId;
    final typed = _query.trim();
    bool shown(ModelOption m) => _matches(m);

    // Just the friendly name: no raw ids or context sizes (D-182).
    Widget tile(ModelOption m) => ListTile(
      key: Key('model-${m.id}'),
      title: Text(m.name.isEmpty ? m.id : m.name),
      trailing: m.id == widget.current ? const Icon(LucideIcons.check) : null,
      onTap: () => Navigator.of(context).pop(m.id),
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.chooseModel,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('modelSearch'),
                controller: _search,
                autofocus: true,
                autocorrect: false,
                decoration: InputDecoration(
                  prefixIcon: const Icon(LucideIcons.search),
                  hintText: l10n.searchModels,
                ),
                onChanged: (v) => setState(() => _query = v),
                onSubmitted: (v) {
                  if (!cloud && v.trim().isNotEmpty) {
                    Navigator.of(context).pop(v.trim());
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncView(
            value: async,
            onRetry: () =>
                ref.invalidate(modelOptionsProvider(widget.credentialId)),
            loading: const _ModelListSkeleton(),
            data: (list) {
              final featured = list.items
                  .where((m) => m.featured == true && shown(m))
                  .toList();
              final rest = list.items
                  .where((m) => m.featured != true && shown(m))
                  .toList();
              final exact = list.items.any((m) => m.id == typed);
              // Built lazily: OpenRouter alone lists several hundred models.
              final rows = <Widget Function()>[
                if (!cloud &&
                    list.source_ == ModelOptionListSource_Enum.featured)
                  () => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      l10n.modelListFallback(list.error.orPlaceholder('')),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (!cloud && typed.isNotEmpty && !exact)
                  () => ListTile(
                    key: const Key('customModel'),
                    leading: const Icon(LucideIcons.pencil),
                    title: Text(l10n.useCustomModel(typed)),
                    onTap: () => Navigator.of(context).pop(typed),
                  ),
                if (featured.isNotEmpty) () => _Header(l10n.recommendedModels),
                for (final m in featured) () => tile(m),
                if (rest.isNotEmpty) () => _Header(l10n.allModels),
                for (final m in rest) () => tile(m),
                if (featured.isEmpty && rest.isEmpty && typed.isEmpty)
                  () => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.noModelsFound),
                  ),
              ];
              return ListView.builder(
                padding: EdgeInsets.only(bottom: BottomPadding.of(context)),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: rows.length,
                itemBuilder: (_, i) => rows[i](),
              );
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
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}

/// The model list while it loads: the recommended header over model rows, in the real header's
/// and rows' sizes. Doesn't scroll; what runs past the sheet is clipped.
class _ModelListSkeleton extends StatelessWidget {
  const _ModelListSkeleton();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SkeletonScope(
      child: ClipRect(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SkeletonText(style: text.labelLarge, width: 120),
              ),
              for (final w in const [0.46, 0.38, 0.52, 0.34, 0.44, 0.4])
                SizedBox(
                  // A one-line ListTile.
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 16, end: 24),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SkeletonText(style: text.bodyLarge, widthFactor: w),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

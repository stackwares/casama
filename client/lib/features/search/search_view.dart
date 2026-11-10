import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../files/file_preview.dart';

/// One search box over the workspace (D-103): messages, chats, memories, skills, routines, tickets
/// and files on awake computers, grouped by type. Cmd/Ctrl+K on desktop and web, a tab on phones.
Future<void> showWorkspaceSearch(BuildContext context) => showAdaptiveSheet<void>(
      context: context,
      heightFactor: 0.9,
      dialogMaxWidth: 680,
      dialogMaxHeight: 720,
      builder: (_) => const SearchView(inSheet: true),
    );

/// Search as a full screen (the phone tab).
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: SafeArea(child: SearchView()));
}

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key, this.inSheet = false});
  final bool inSheet;

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final _q = TextEditingController();
  Timer? _debounce;
  SearchResponse? _results;
  Object? _error;
  var _loading = false;
  var _seq = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _changed(String v) {
    _debounce?.cancel();
    if (v.trim().length < 2) {
      setState(() {
        _results = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () => _run(v.trim()));
  }

  Future<void> _run(String q) async {
    final org = ref.read(currentOrgProvider);
    if (org == null) return;
    final seq = ++_seq;
    setState(() => _loading = true);
    try {
      final r = await ref.read(backendProvider).search(org.id, q);
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = r;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _open(String location) {
    if (widget.inSheet) Navigator.of(context).pop();
    GoRouter.of(context).go(location);
  }

  (IconData, String) _kind(SearchKind k) {
    final l10n = context.l10n;
    return switch (k) {
      SearchKind.message => (LucideIcons.messageSquare, l10n.searchMessages),
      SearchKind.chat => (LucideIcons.messagesSquare, l10n.searchChats),
      SearchKind.memory => (LucideIcons.brain, l10n.memory),
      SearchKind.skill => (LucideIcons.sparkles, l10n.skills),
      SearchKind.routine => (LucideIcons.clock, l10n.routines),
      SearchKind.ticket => (LucideIcons.squareKanban, l10n.searchTickets),
    };
  }

  String? _target(SearchResult r) => switch (r.kind) {
        SearchKind.message when r.botId != null => '/bots/${r.botId}/chat?c=${r.conversationId}&m=${r.id}',
        SearchKind.chat when r.botId != null => '/bots/${r.botId}/chat?c=${r.conversationId}',
        SearchKind.memory when r.botId != null => '/bots/${r.botId}/memory',
        SearchKind.routine when r.botId != null => '/bots/${r.botId}/routines',
        SearchKind.skill => '/settings/skills',
        SearchKind.ticket => '/tasks',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    ref.watch(currentOrgProvider); // keeps the workspace loaded for searches
    final r = _results;
    final groups = <SearchKind, List<SearchResult>>{};
    for (final item in r?.items ?? const <SearchResult>[]) {
      (groups[item.kind] ??= []).add(item);
    }
    Widget header(IconData icon, String label) => Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.xs),
          child: Row(
            children: [
              Icon(icon, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: TextField(
            key: const Key('searchField'),
            controller: _q,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: const Icon(LucideIcons.search, size: 20),
              suffixIcon: _loading ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))) : null,
            ),
            onChanged: _changed,
            onSubmitted: (v) => v.trim().length >= 2 ? _run(v.trim()) : null,
          ),
        ),
        Expanded(
          child: _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(AppSpace.lg), child: Text(errorText(context, _error!))))
              : r == null
                  ? Center(child: Text(l10n.searchEmptyPrompt, style: TextStyle(color: scheme.onSurfaceVariant)))
                  : r.items.isEmpty && r.files.isEmpty
                      ? Center(child: Text(l10n.searchNoResults(r.query), style: TextStyle(color: scheme.onSurfaceVariant)))
                      : ListView(
                          padding: const EdgeInsets.only(bottom: AppSpace.xl),
                          children: [
                            for (final entry in groups.entries) ...[
                              header(_kind(entry.key).$1, _kind(entry.key).$2),
                              for (final item in entry.value)
                                ListTile(
                                  key: Key('result-${item.kind.name}-${item.id}'),
                                  title: Text(item.title.isEmpty ? _kind(item.kind).$2 : item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  subtitle: item.snippet.isEmpty ? null : _Snippet(item.snippet),
                                  onTap: _target(item) == null ? null : () => _open(_target(item)!),
                                ),
                            ],
                            if (r.files.isNotEmpty) ...[
                              header(LucideIcons.fileText, l10n.searchFiles),
                              for (final f in r.files)
                                ListTile(
                                  key: Key('file-${f.computerId}-${f.path}'),
                                  leading: Icon(f.match == FileSearchResultMatchEnum.name ? LucideIcons.file : LucideIcons.fileSearch, size: 20),
                                  title: Text(f.path, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  subtitle: Text(f.computerName),
                                  onTap: () => showComputerFile(context, computerId: f.computerId, path: f.path),
                                ),
                            ],
                            if (r.filesSearched == 0)
                              Padding(
                                padding: const EdgeInsets.all(AppSpace.md),
                                child: Text(l10n.searchFilesAsleep, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                              ),
                          ],
                        ),
        ),
      ],
    );
  }
}

/// A snippet with the matched words (between « ») in bold.
class _Snippet extends StatelessWidget {
  const _Snippet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final parts = text.split(RegExp('[«»]'));
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(TextSpan(text: parts[i], style: i.isOdd ? TextStyle(fontWeight: FontWeight.w700, color: context.appColors.warning) : null));
    }
    return Text.rich(TextSpan(children: spans), maxLines: 2, overflow: TextOverflow.ellipsis);
  }
}

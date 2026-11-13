import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/shortcuts.dart' show askPath;
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/bottom_padding.dart';
import '../../ui/edge_fade.dart';
import '../../ui/reveal_when_selected.dart';
import '../../ui/shell_header.dart';
import '../board/board_screen.dart' show TicketSheet;
import '../bots/bots_screen.dart' show byRecentChat, chatListTime, lastMessagePreview;
import '../files/file_preview.dart';
import '../library/creation_tile.dart' show creationIcon, creationKindLabel;
import '../home/home_shell.dart' show LayoutSize, layoutFor;
import 'recent_searches.dart';
import 'search_rows.dart';

/// One search box over the workspace (D-103): messages, chats, memories, skills, routines, tickets
/// and files on awake computers, grouped by type. Cmd/Ctrl+K on desktop and web, the round button
/// beside the tab bar on phones (D-176).
///
/// Before anything is typed it answers "where was I?" and "where can I go?" (D-235): recent
/// searches, the chats you were last in, what's waiting for you, and places to jump to. Typing
/// matches bots and places at once, then the server from two characters; chips scope the search,
/// arrow keys and Enter drive it, and a search that finds nothing offers to ask a bot instead.
Future<void> showWorkspaceSearch(BuildContext context) => showAdaptiveSheet<void>(
      context: context,
      heightFactor: 0.9,
      contentPadsBottom: true,
      dialogMaxWidth: 680,
      dialogMaxHeight: 720,
      builder: (_) => const SearchView(inSheet: true),
    );

/// Search as a full screen, for links to `/search`; the app itself opens [showWorkspaceSearch].
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ShellHeader(title: context.l10n.search, phoneFallback: '/bots'),
    body: const SafeArea(top: false, bottom: false, child: SearchView()),
  );
}

/// What a search covers: everything, or one kind (D-235). Chats covers chat titles and messages.
enum SearchScope {
  all([]),
  chats(['chat', 'message']),
  memories(['memory']),
  skills(['skill']),
  routines(['routine']),
  tickets(['ticket']),
  files(['file']),

  /// What bots made (the Library, D-274), searched by title and bot through `/v1/creations`.
  library(['creation']);

  const SearchScope(this.kinds);
  final List<String> kinds;

  bool includes(SearchKind k) => this == all || kinds.contains(k.value);
  bool get coversFiles => this == all || this == files;
  bool get coversLibrary => this == all || this == library;

  /// The kinds sent to the server's search (the Library isn't one of them).
  List<String>? get serverKinds => this == all ? null : kinds.where((k) => k != 'creation').toList();
}

/// A place to jump to, matched by its name or a few other words for it.
class _Place {
  const _Place(this.id, this.icon, this.label, this.location, {this.words = '', this.push = false});
  final String id;
  final IconData icon;
  final String label;
  final String location;
  final String words;

  /// Opened on top of the current screen (Quick ask) instead of replacing it.
  final bool push;

  bool matches(String lower) => label.toLowerCase().contains(lower) || words.contains(lower);
}

/// The places shown before anything is typed, in this order.
const _suggestedPlaces = ['ask', 'tasks', 'skills', 'settings'];

sealed class _Entry {
  const _Entry();
}

class _Header extends _Entry {
  const _Header(this.label, {this.action});
  final String label;
  final Widget? action;
}

class _RecentChips extends _Entry {
  const _RecentChips(this.items);
  final List<String> items;
}

class _Note extends _Entry {
  const _Note(this.text, {this.action});
  final String text;
  final Widget? action;
}

class _Row extends _Entry {
  const _Row({required this.key, required this.leading, required this.title, this.subtitle, this.trailing, required this.open});
  final Key key;
  final Widget leading;
  final String title;
  final InlineSpan? subtitle;
  final String? trailing;
  final VoidCallback? open;
}

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key, this.inSheet = false});
  final bool inSheet;

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final _q = TextEditingController();
  final _list = ScrollController();
  Timer? _debounce;
  SearchResponse? _results;

  /// Library matches for the same words (LIBRARY-PLAN §5.6).
  List<Creation> _creations = const [];
  Object? _error;
  var _loading = false;
  var _seq = 0;
  var _scope = SearchScope.all;

  /// How many results each scope has, from the last unscoped search of [_countsQuery].
  Map<SearchScope, int> _counts = const {};
  String? _countsQuery;

  /// The selected row (arrow keys, pointer), or -1. Rows from the last build, for the keys.
  var _sel = -1;
  List<_Row> _rows = const [];
  final _rowKeys = <GlobalKey>[];

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    _list.dispose();
    super.dispose();
  }

  /// Windows with a keyboard start with the first row selected, so Enter opens it.
  bool get _keyboardFirst => layoutFor(MediaQuery.sizeOf(context).width) != LayoutSize.phone;

  void _resetSelection() => _sel = _keyboardFirst ? 0 : -1;

  void _changed(String v) {
    _debounce?.cancel();
    setState(() {
      _resetSelection();
      if (v.trim().length < 2) {
        _results = null;
        _error = null;
        _loading = false;
        _seq++;
      }
    });
    if (v.trim().length < 2) return;
    _debounce = Timer(const Duration(milliseconds: 250), () => _run(v.trim()));
  }

  Future<void> _run(String q) async {
    final org = ref.read(currentOrgProvider);
    if (org == null) return;
    final seq = ++_seq;
    final scope = _scope;
    setState(() => _loading = true);
    try {
      final backend = ref.read(backendProvider);
      final library = scope.coversLibrary
          ? backend.creations(org.id, q: q, limit: 20).then((l) => l.items).catchError((Object _) => const <Creation>[])
          : Future.value(const <Creation>[]);
      final r = scope == SearchScope.library ? SearchResponse(query: q, items: const [], files: const [], filesSearched: 0) : await backend.search(org.id, q, kinds: scope.serverKinds);
      final creations = await library;
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = r;
        _creations = creations;
        _error = null;
        _loading = false;
        _resetSelection();
        if (scope == SearchScope.all) {
          _countsQuery = q;
          _counts = {
            for (final s in SearchScope.values.skip(1))
              s: s == SearchScope.files ? r.files.length : s == SearchScope.library ? creations.length : r.items.where((i) => s.includes(i.kind)).length,
          };
        }
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _setScope(SearchScope s) {
    if (s == _scope) return;
    setState(() {
      _scope = s;
      _resetSelection();
    });
    final q = _q.text.trim();
    if (q.length >= 2) {
      _debounce?.cancel();
      unawaited(_run(q));
    }
  }

  void _setQuery(String q) {
    _q.value = TextEditingValue(text: q, selection: TextSelection.collapsed(offset: q.length));
    _changed(q);
  }

  /// Leaves search for [location], remembering the query when it found what was opened.
  void _go(String location, {bool push = false}) {
    final q = _q.text.trim();
    if (q.length >= 2) ref.read(recentSearchesProvider.notifier).add(q);
    final router = GoRouter.of(context);
    if (widget.inSheet) Navigator.of(context).pop();
    push ? unawaited(router.push(location)) : router.go(location);
  }

  /// Tickets open on the board, with the ticket's own sheet on top.
  void _openTicket(String id) {
    final router = GoRouter.of(context);
    _go('/tasks');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = router.routerDelegate.navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      unawaited(showAdaptiveSheet<void>(context: ctx, contentPadsBottom: true, builder: (_) => TicketSheet(taskId: id)));
    });
  }

  (IconData, String) _kind(SearchKind k) {
    final l10n = context.l10n;
    return switch (k) {
      SearchKind.message => (LucideIcons.messageSquare, l10n.searchMessages),
      SearchKind.chat => (LucideIcons.messagesSquare, l10n.searchChats),
      SearchKind.memory => (LucideIcons.brain, l10n.searchMemories),
      SearchKind.skill => (LucideIcons.bookOpen, l10n.skills),
      SearchKind.routine => (LucideIcons.clock, l10n.routines),
      SearchKind.ticket => (LucideIcons.squareKanban, l10n.searchTickets),
    };
  }

  String _scopeLabel(SearchScope s) {
    final l10n = context.l10n;
    return switch (s) {
      SearchScope.all => l10n.searchScopeAll,
      SearchScope.chats => l10n.searchChats,
      SearchScope.memories => l10n.searchMemories,
      SearchScope.skills => l10n.skills,
      SearchScope.routines => l10n.routines,
      SearchScope.tickets => l10n.searchTickets,
      SearchScope.files => l10n.searchFiles,
      SearchScope.library => l10n.library,
    };
  }

  /// Where a result opens: the message in its chat, or the item itself on its screen.
  VoidCallback? _target(SearchResult r) => switch (r.kind) {
        SearchKind.message when r.botId != null => () => _go('/bots/${r.botId}/chat?c=${r.conversationId}&m=${r.id}'),
        SearchKind.chat when r.botId != null => () => _go('/bots/${r.botId}/chat?c=${r.conversationId}'),
        SearchKind.memory when r.botId != null => () => _go('/bots/${r.botId}/memory?focus=${r.id}'),
        SearchKind.routine when r.botId != null => () => _go('/bots/${r.botId}/routines?focus=${r.id}'),
        SearchKind.skill => () => _go('/settings/skills?focus=${r.id}'),
        SearchKind.ticket => () => _openTicket(r.id),
        _ => null,
      };

  List<_Place> _places() {
    final l10n = context.l10n;
    return [
      _Place('ask', LucideIcons.sparkles, l10n.quickAsk, '/quick-ask', words: 'ask question new chat', push: true),
      _Place('chats', LucideIcons.messagesSquare, l10n.navChats, '/bots', words: 'bots conversations'),
      _Place('inbox', LucideIcons.inbox, l10n.inbox, '/inbox', words: 'approvals notifications'),
      _Place('tasks', LucideIcons.listTodo, l10n.navTasks, '/tasks', words: 'tickets board todo'),
      _Place('projects', LucideIcons.folderKanban, l10n.projects, '/projects'),
      _Place('library', LucideIcons.library, l10n.library, '/library', words: 'pages sites games pictures images videos documents files made creations'),
      _Place('skills', LucideIcons.bookOpen, l10n.skills, '/settings/skills', words: 'catalog'),
      _Place('computers', LucideIcons.monitor, l10n.computers, '/settings/computers', words: 'machines'),
      _Place('usage', LucideIcons.chartColumn, l10n.usage, '/settings/usage', words: 'cost spend billing'),
      _Place('settings', LucideIcons.settings, l10n.settings, '/settings', words: 'preferences account'),
    ];
  }

  _Row _placeRow(_Place p) => _Row(
        key: Key('place-${p.id}'),
        leading: SearchIconTile(p.icon, color: context.colorScheme.primary),
        title: p.label,
        open: () => _go(p.location, push: p.push),
      );

  /// A bot's row: its last message and when, opening that chat.
  _Row _botRow(Bot b, String keyPrefix) {
    final last = b.lastMessage;
    final preview = lastMessagePreview(context, b);
    return _Row(
      key: Key('$keyPrefix-${b.id}'),
      leading: BotAvatar(name: b.name, avatar: b.avatarUrl, size: 36, status: b.status),
      title: b.name,
      subtitle: preview == null ? null : TextSpan(text: preview),
      trailing: last == null ? null : chatListTime(context, last.at),
      open: () => _go(last == null ? '/bots/${b.id}/chat' : '/bots/${b.id}/chat?c=${last.conversationId}'),
    );
  }

  /// Before anything is typed: recent searches, recent chats, what's waiting, places.
  List<_Entry> _suggestions(List<Bot> bots) {
    final l10n = context.l10n;
    final recent = ref.watch(recentSearchesProvider);
    final waiting = ref.watch(inboxBadgeProvider);
    final chats = byRecentChat(bots).where((b) => b.lastMessage != null).take(4);
    final places = {for (final p in _places()) p.id: p};
    return [
      if (recent.isNotEmpty) ...[
        _Header(
          l10n.searchRecent,
          action: TextButton(
            key: const Key('clearRecent'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: ref.read(recentSearchesProvider.notifier).clear,
            child: Text(l10n.searchClearRecent),
          ),
        ),
        _RecentChips(recent),
      ],
      if (chats.isNotEmpty) ...[
        _Header(l10n.searchJumpBackIn),
        for (final b in chats) _botRow(b, 'recentChat'),
      ],
      if (waiting > 0) ...[
        _Header(l10n.searchNeedsYou),
        _Row(
          key: const Key('needsYou'),
          leading: SearchIconTile(LucideIcons.inbox, color: context.appColors.warning),
          title: l10n.searchWaiting(waiting),
          open: () => _go('/inbox'),
        ),
      ],
      _Header(l10n.searchGoTo),
      for (final id in _suggestedPlaces) _placeRow(places[id]!),
    ];
  }

  /// While typing: bots and places at once, then the server's results, then "ask a bot".
  List<_Entry> _matches(String q, List<Bot> bots) {
    final l10n = context.l10n;
    final lower = q.toLowerCase();
    final all = _scope == SearchScope.all;
    final botHits = all ? bots.where((b) => b.name.toLowerCase().contains(lower)).take(3).toList() : const <Bot>[];
    final placeHits = all ? _places().where((p) => p.matches(lower)).take(3).toList() : const <_Place>[];
    final botsById = {for (final b in bots) b.id: b};
    final r = _results;
    final items = (r?.items ?? const <SearchResult>[]).where((i) => _scope.includes(i.kind)).toList();
    final files = _scope.coversFiles ? (r?.files ?? const <FileSearchResult>[]) : const <FileSearchResult>[];
    final groups = <SearchKind, List<SearchResult>>{};
    for (final kind in SearchKind.values) {
      final of = items.where((i) => i.kind == kind).toList();
      if (of.isNotEmpty) groups[kind] = of;
    }
    final creations = _scope.coversLibrary ? _creations : const <Creation>[];
    final searched = q.length >= 2 && r != null && _error == null;
    final nothing = searched && items.isEmpty && files.isEmpty && creations.isEmpty && botHits.isEmpty && placeHits.isEmpty;
    final askBot = byRecentChat(bots).firstOrNull;
    final ask = askBot == null || q.length < 2
        ? null
        : _Row(
            key: const Key('askBot'),
            leading: BotAvatar(name: askBot.name, avatar: askBot.avatarUrl, size: 36),
            title: l10n.searchAskBot(askBot.name, q),
            subtitle: TextSpan(text: l10n.searchAskBotHelp),
            open: () => _go(askPath(botId: askBot.id, text: q), push: true),
          );
    return [
      if (botHits.isNotEmpty || placeHits.isNotEmpty) ...[
        _Header(l10n.searchTopHits),
        for (final b in botHits) _botRow(b, 'botHit'),
        for (final p in placeHits) _placeRow(p),
      ],
      if (q.length < 2)
        _Note(l10n.searchKeepTyping)
      else if (_error != null)
        _Note(
          errorText(context, _error!),
          action: TextButton.icon(
            key: const Key('searchRetry'),
            onPressed: () => _run(q),
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: Text(l10n.retry),
          ),
        )
      else if (nothing) ...[
        _Note(l10n.searchNoResults(q)),
        ?ask,
      ] else ...[
        for (final entry in groups.entries) ...[
          _Header(_kind(entry.key).$2),
          for (final item in entry.value) _resultRow(item, botsById),
        ],
        if (creations.isNotEmpty) ...[
          _Header(l10n.library),
          for (final c in creations)
            _Row(
              key: Key('result-creation-${c.id}'),
              leading: SearchIconTile(creationIcon(c.kind, label: c.label)),
              title: c.title,
              subtitle: TextSpan(text: [creationKindLabel(l10n, c), if ((c.botName ?? '').isNotEmpty) c.botName!, relativeTime(c.createdAt, context)].join(' · ')),
              open: () => _go('/library/${c.id}', push: true),
            ),
        ],
        if (files.isNotEmpty) ...[
          _Header(l10n.searchFiles),
          for (final f in files)
            _Row(
              key: Key('file-${f.computerId}-${f.path}'),
              leading: SearchIconTile(f.match == FileSearchResultMatchEnum.name ? LucideIcons.file : LucideIcons.fileSearch),
              title: f.path.split('/').last,
              subtitle: TextSpan(text: '${f.computerName} · ${f.path}'),
              open: () {
                final q = _q.text.trim();
                if (q.length >= 2) ref.read(recentSearchesProvider.notifier).add(q);
                showComputerFile(context, computerId: f.computerId, path: f.path);
              },
            ),
        ],
        if (searched && r.filesSearched == 0 && _scope.coversFiles) _Note(l10n.searchFilesAsleep),
        if (ask != null) ...[
          _Header(l10n.quickAsk),
          ask,
        ],
      ],
    ];
  }

  _Row _resultRow(SearchResult item, Map<String, Bot> botsById) {
    final (icon, label) = _kind(item.kind);
    final bot = item.botId == null ? null : botsById[item.botId];
    final meta = [
      if (bot != null) bot.name,
      if (item.kind == SearchKind.message || item.kind == SearchKind.chat) relativeTime(item.createdAt, context),
    ].join(' · ');
    final snippet = snippetSpans(context, item.snippet);
    final showBot = bot != null && (item.kind == SearchKind.message || item.kind == SearchKind.chat);
    return _Row(
      key: Key('result-${item.kind.name}-${item.id}'),
      leading: showBot ? BotAvatar(name: bot.name, avatar: bot.avatarUrl, size: 36) : SearchIconTile(icon),
      title: item.title.isEmpty ? label : item.title,
      subtitle: meta.isEmpty && snippet.isEmpty
          ? null
          : TextSpan(children: [
              if (meta.isNotEmpty) TextSpan(text: meta, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (meta.isNotEmpty && snippet.isNotEmpty) const TextSpan(text: '  '),
              ...snippet,
            ]),
      open: _target(item),
    );
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = e.logicalKey;
    if (key == LogicalKeyboardKey.escape && _q.text.isNotEmpty) {
      _setQuery('');
      return KeyEventResult.handled;
    }
    final n = _rows.length;
    if (n == 0 || (key != LogicalKeyboardKey.arrowDown && key != LogicalKeyboardKey.arrowUp)) return KeyEventResult.ignored;
    setState(() {
      if (key == LogicalKeyboardKey.arrowDown) {
        _sel = _sel < 0 ? 0 : (_sel + 1) % n;
      } else {
        _sel = _sel <= 0 ? n - 1 : _sel - 1;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _sel >= 0 && _sel < _rowKeys.length ? _rowKeys[_sel].currentContext : null;
      if (ctx != null && ctx.mounted) {
        unawaited(Scrollable.ensureVisible(ctx, duration: AppMotion.of(context, AppMotion.fast), alignmentPolicy: key == LogicalKeyboardKey.arrowDown ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd : ScrollPositionAlignmentPolicy.keepVisibleAtStart));
      }
    });
    return KeyEventResult.handled;
  }

  void _submitted(String v) {
    if (_sel >= 0 && _sel < _rows.length && _rows[_sel].open != null) {
      _rows[_sel].open!();
    } else if (v.trim().length >= 2) {
      _debounce?.cancel();
      unawaited(_run(v.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    ref.watch(currentOrgProvider); // keeps the workspace loaded for searches
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    final q = _q.text.trim();
    final entries = q.isEmpty ? _suggestions(bots) : _matches(q, bots);
    _rows = entries.whereType<_Row>().toList();
    while (_rowKeys.length < _rows.length) {
      _rowKeys.add(GlobalKey());
    }
    if (_sel >= _rows.length) _sel = _rows.isEmpty ? -1 : 0;
    final keyboard = _keyboardFirst;
    final counts = _countsQuery == q ? _counts : const <SearchScope, int>{};
    var rowIndex = 0;

    Widget entry(_Entry e) {
      switch (e) {
        case _Header():
          return SearchSectionHeader(e.label, action: e.action);
        case _RecentChips():
          return Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.xxs),
            child: Wrap(
              spacing: AppSpace.xs,
              runSpacing: AppSpace.xs,
              children: [
                for (final s in e.items)
                  InputChip(
                    key: Key('recentSearch-$s'),
                    avatar: const Icon(LucideIcons.history, size: 16),
                    label: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onPressed: () => _setQuery(s),
                    deleteIcon: const Icon(LucideIcons.x, size: 14),
                    deleteButtonTooltipMessage: l10n.searchRemoveRecent,
                    onDeleted: () => ref.read(recentSearchesProvider.notifier).remove(s),
                  ),
              ],
            ),
          );
        case _Note():
          return Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.md + AppSpace.xs, AppSpace.md, AppSpace.md, AppSpace.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.text, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                ?e.action,
              ],
            ),
          );
        case _Row():
          final i = rowIndex++;
          return KeyedSubtree(
            key: _rowKeys[i],
            child: SearchRowTile(
              key: e.key,
              leading: e.leading,
              title: e.title,
              subtitle: e.subtitle,
              trailing: e.trailing,
              selected: i == _sel,
              showEnter: keyboard,
              onTap: e.open,
              onHover: keyboard && _sel != i ? () => setState(() => _sel = i) : null,
            ),
          );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.xs),
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: _onKey,
            child: TextField(
              key: const Key('searchField'),
              controller: _q,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchJumpHint,
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                suffixIcon: _q.text.isEmpty
                    ? null
                    : IconButton(
                        key: const Key('clearSearch'),
                        tooltip: l10n.searchClear,
                        icon: const Icon(LucideIcons.x, size: 18),
                        onPressed: () => _setQuery(''),
                      ),
              ),
              onChanged: _changed,
              onSubmitted: _submitted,
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: EdgeFade(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
              child: Row(
                spacing: AppSpace.xs,
                children: [
                  for (final s in SearchScope.values)
                    RevealWhenSelected(
                      selected: _scope == s,
                      child: ChoiceChip(
                        key: Key('searchScope-${s.name}'),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          (counts[s] ?? 0) > 0 ? '${_scopeLabel(s)}  ${counts[s]}' : _scopeLabel(s),
                          style: const TextStyle(fontFeatures: AppText.tabular),
                        ),
                        selected: _scope == s,
                        onSelected: (_) => _setScope(s),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 2, child: _loading ? const LinearProgressIndicator(key: Key('searchLoading'), minHeight: 2) : null),
        Expanded(
          child: ListView(
            controller: _list,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(bottom: keyboard ? AppSpace.md : BottomPadding.of(context, minimum: AppSpace.xl)),
            children: [for (final e in entries) entry(e)],
          ),
        ),
        if (keyboard)
          DecoratedBox(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: context.appColors.hairline))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md + AppSpace.xs, vertical: AppSpace.xs),
              child: Text(
                l10n.searchKeysHint,
                key: const Key('searchKeysHint'),
                style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
      ],
    );
  }
}

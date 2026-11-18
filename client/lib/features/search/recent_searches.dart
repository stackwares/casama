import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';

/// The last few searches someone opened a result from, newest first (D-235). Kept on this device
/// only, per person and workspace, so a shared computer never shows one account's searches to
/// another. A search is saved when a result is opened, not on every keystroke.
final recentSearchesProvider = NotifierProvider<RecentSearches, List<String>>(RecentSearches.new);

class RecentSearches extends Notifier<List<String>> {
  static const max = 5;

  String? get _key {
    final org = ref.read(currentOrgProvider)?.id;
    final user = ref.read(backendProvider).userId;
    return org == null || user == null ? null : 'search.recent.$user.$org';
  }

  @override
  List<String> build() {
    ref.watch(currentOrgProvider.select((o) => o?.id));
    unawaited(_load());
    return const [];
  }

  Future<void> _load() async {
    final key = _key;
    if (key == null) return;
    try {
      final saved = (await SharedPreferences.getInstance()).getStringList(key);
      if (saved != null && _key == key) state = saved.take(max).toList();
    } catch (_) {
      // Storage unavailable (private window, tests): search simply has no history.
    }
  }

  Future<void> _save() async {
    final key = _key;
    if (key == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      state.isEmpty ? await prefs.remove(key) : await prefs.setStringList(key, state);
    } catch (_) {}
  }

  /// Puts [query] first, dropping an older copy (ignoring case) and anything past [max].
  void add(String query) {
    final q = query.trim();
    if (q.length < 2) return;
    state = [q, ...state.where((s) => s.toLowerCase() != q.toLowerCase())].take(max).toList();
    unawaited(_save());
  }

  void remove(String query) {
    state = state.where((s) => s != query).toList();
    unawaited(_save());
  }

  void clear() {
    state = const [];
    unawaited(_save());
  }
}

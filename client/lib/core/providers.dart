import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import 'backend.dart';

/// The backend; overridden in main() and in tests.
final backendProvider = Provider<Backend>((ref) => throw UnimplementedError('backendProvider must be overridden'));

/// Signed-in state, updated from the backend's auth stream.
final signedInProvider = StreamProvider<bool>((ref) async* {
  final backend = ref.watch(backendProvider);
  yield backend.isSignedIn;
  yield* backend.signedInChanges;
});

final organizationsProvider = FutureProvider<List<OrganizationWithRole>>((ref) async {
  final signedIn = ref.watch(signedInProvider).value ?? false;
  if (!signedIn) return const [];
  return ref.watch(backendProvider).organizations();
});

/// The selected workspace id (defaults to the first one).
class SelectedOrg extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

final selectedOrgIdProvider = NotifierProvider<SelectedOrg, String?>(SelectedOrg.new);

final currentOrgProvider = Provider<OrganizationWithRole?>((ref) {
  final orgs = ref.watch(organizationsProvider).value ?? const [];
  if (orgs.isEmpty) return null;
  final id = ref.watch(selectedOrgIdProvider);
  return orgs.firstWhere((o) => o.id == id, orElse: () => orgs.first);
});

final botsProvider = FutureProvider<List<Bot>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).bots(org.id);
});

final botProvider = Provider.family<Bot?, String>((ref, id) {
  final bots = ref.watch(botsProvider).value ?? const [];
  for (final b in bots) {
    if (b.id == id) return b;
  }
  return null;
});

final credentialsProvider = FutureProvider<List<Credential>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).credentials(org.id);
});

final usageTodayProvider = FutureProvider<UsageReport?>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return null;
  return ref.watch(backendProvider).usage(org.id, period: 'day');
});

final usageMonthProvider = FutureProvider<UsageReport?>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return null;
  return ref.watch(backendProvider).usage(org.id, period: 'month');
});

final computersProvider = FutureProvider<List<Computer>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).computers(org.id);
});

final conversationsProvider = FutureProvider.family<List<Conversation>, String>(
  (ref, botId) => ref.watch(backendProvider).conversations(botId),
);

final memoriesProvider = FutureProvider.family<List<Memory>, String>(
  (ref, botId) => ref.watch(backendProvider).memories(botId),
);

final skillsProvider = FutureProvider<List<SkillView>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).skills(org.id);
});

final runsProvider = FutureProvider.family<List<RunSummary>, String>(
  (ref, botId) => ref.watch(backendProvider).runs(botId),
);

final runEventsProvider = FutureProvider.family<List<RunEventItem>, String>(
  (ref, runId) => ref.watch(backendProvider).runEvents(runId),
);

/// Formats US dollars for cost meters.
String formatUsd(num value) {
  if (value >= 1) return '\$${value.toStringAsFixed(2)}';
  if (value == 0) return '\$0.00';
  return '\$${value.toStringAsFixed(4)}';
}

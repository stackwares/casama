import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers.dart';
import 'router.dart';

/// Shortcuts (D-111): "Ask a bot" and "Run a routine" from Siri, Spotlight and Shortcuts on iOS
/// and macOS (App Intents in the Runner), and app shortcuts on Android (quick_actions).

bool get _apple => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);
bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

const _channel = MethodChannel('kasama/shortcuts');

/// The paths shortcuts open: `/quick-ask?bot=…&text=…` and `/run-routine/<routine>:<bot>`.
String askPath({String? botId, String text = ''}) =>
    Uri(path: '/quick-ask', queryParameters: {'text': text, 'bot': ?botId}).toString();
String routinePath(String routineId, String botId) => '/run-routine/$routineId:$botId';

/// What the App Intents list: the workspace's bots and their routines (names and ids only).
String shortcutsJson(List<Bot> bots, Map<String, List<Routine>> routines) => jsonEncode({
      'bots': [for (final b in bots) {'id': b.id, 'name': b.name}],
      'routines': [
        for (final b in bots)
          for (final r in routines[b.id] ?? const <Routine>[]) {'id': '${r.id}:${b.id}', 'name': r.name, 'detail': b.name},
      ],
    });

final shortcutsProvider = Provider<void>((ref) {
  if (!_apple && !_android) return;
  final router = ref.read(routerProvider);
  if (_apple) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'open' && call.arguments is String) router.go(call.arguments as String);
    });
    unawaited(_channel.invokeMethod<String>('ready').then((p) {
      if (p != null && p.isNotEmpty) router.go(p);
    }).catchError((_) {}));
  }
  final actions = _android ? const QuickActions() : null;
  if (actions != null) {
    unawaited(actions.initialize((type) {
      if (type == 'ask') router.go(askPath());
      if (type.startsWith('ask:')) router.go(askPath(botId: type.substring(4)));
      if (type.startsWith('routine:')) router.go('/run-routine/${type.substring(8)}');
    }).catchError((_) {}));
  }

  Future<void> sync(List<Bot> bots) async {
    final routines = <String, List<Routine>>{};
    for (final b in bots.take(20)) {
      routines[b.id] = await ref.read(backendProvider).routines(b.id).catchError((_) => const <Routine>[]);
    }
    if (_apple) {
      try {
        await (await SharedPreferences.getInstance()).setString('kasama.shortcuts', shortcutsJson(bots, routines));
      } catch (_) {}
    }
    if (actions != null) {
      final firstRoutine = [for (final b in bots) for (final r in routines[b.id] ?? const <Routine>[]) (r, b)].firstOrNull;
      try {
        await actions.setShortcutItems([
          const ShortcutItem(type: 'ask', localizedTitle: 'Quick ask', icon: 'ic_shortcut_ask'),
          for (final b in bots.take(2)) ShortcutItem(type: 'ask:${b.id}', localizedTitle: 'Ask ${b.name}', icon: 'ic_shortcut_ask'),
          if (firstRoutine != null)
            ShortcutItem(type: 'routine:${firstRoutine.$1.id}:${firstRoutine.$2.id}', localizedTitle: 'Run ${firstRoutine.$1.name}', icon: 'ic_shortcut_routine'),
        ]);
      } catch (_) {}
    }
  }

  ref.listen(botsProvider, (_, next) {
    final bots = next.value;
    if (bots != null) unawaited(sync(bots));
  }, fireImmediately: true);
});

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../l10n/generated/app_localizations.dart';
import 'providers.dart';
import 'router.dart';

/// App Group shared by the app and its iOS widget and share extensions.
const appGroupId = 'group.ai.casama.app';

bool get _ios => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Keeps the home-screen widget (iOS and Android) showing a bot's status and today's cost.
final homeWidgetSyncProvider = Provider<void>((ref) {
  if (!_ios && !_android) return;
  if (_ios) unawaited(HomeWidget.setAppGroupId(appGroupId).catchError((_) => null));
  final bots = ref.watch(botsProvider).value;
  final usage = ref.watch(usageTodayProvider).value;
  if (bots == null || bots.isEmpty) return;
  final bot = bots.first;
  final cost = usage?.byBot.where((b) => b.botId == bot.id).firstOrNull?.costUsd ?? 0;
  // No BuildContext here: resolve the device locale against the app's supported ones.
  final l10n = lookupAppLocalizations(basicLocaleListResolution(PlatformDispatcher.instance.locales, AppLocalizations.supportedLocales));
  unawaited(() async {
    try {
      await HomeWidget.saveWidgetData('bot_name', bot.name);
      // `mascot:<name>`, or empty for initials: the widget draws the app's own mark.
      await HomeWidget.saveWidgetData('bot_avatar', bot.avatarUrl ?? '');
      await HomeWidget.saveWidgetData('bot_status', switch (bot.status.value) {
        'working' => l10n.widgetStatusWorking,
        'waiting' => l10n.botStatusWaiting,
        'disabled' => l10n.widgetStatusOff,
        _ => l10n.botStatusIdle,
      });
      await HomeWidget.saveWidgetData('bot_cost', l10n.costToday(formatUsd(cost, l10n.localeName)));
      await HomeWidget.updateWidget(androidName: 'BotStatusWidget', iOSName: 'BotStatusWidget');
    } catch (e) {
      debugPrint('home widget update failed: $e');
    }
  }());
});

/// A file shared into Casama from another app, waiting for quick ask to send it (Fix 15).
class SharedAttachment {
  const SharedAttachment({required this.name, this.mimeType, required this.read});
  final String name;
  final String? mimeType;

  /// Reads the file's bytes (from the share's temporary copy on the device).
  final Future<Uint8List> Function() read;
}

/// Files shared in that quick ask has not sent yet. Quick ask takes them when it opens.
class PendingSharedFiles extends Notifier<List<SharedAttachment>> {
  @override
  List<SharedAttachment> build() => const [];

  void set(List<SharedAttachment> files) => state = files;

  /// Returns what was waiting and clears it.
  List<SharedAttachment> take() {
    final files = state;
    state = const [];
    return files;
  }
}

final pendingSharedFilesProvider = NotifierProvider<PendingSharedFiles, List<SharedAttachment>>(PendingSharedFiles.new);

/// Splits what another app shared into the text for the box and the files to attach: text and
/// links are text; pictures, videos and files are attached as themselves, not as their names.
(String, List<SharedAttachment>) splitSharedMedia(List<SharedMediaFile> items) {
  final text = <String>[];
  final files = <SharedAttachment>[];
  for (final f in items) {
    if (f.type == SharedMediaType.text || f.type == SharedMediaType.url) {
      text.add(f.path);
      continue;
    }
    final path = f.path;
    files.add(SharedAttachment(
      name: path.split('/').last,
      mimeType: f.mimeType,
      read: () => XFile(path).readAsBytes(),
    ));
    final caption = f.message;
    if (caption != null && caption.trim().isNotEmpty && !text.contains(caption)) text.add(caption);
  }
  return (text.join('\n'), files);
}

/// Share to bot: shared text, links and files open quick ask. Android uses receive_sharing_intent;
/// the iOS share extension writes to the App Group and opens casama://app/quick-ask?shared=1.
final shareToBotProvider = Provider<void>((ref) {
  if (!_android) return;
  void open(List<SharedMediaFile> all) {
    // The plugin also reports every ACTION_VIEW intent (notification, widget and casama.ai/open
    // links) as a "url" item. Those are deep links the router already opens, not shares: a link
    // shared from another app arrives as text via ACTION_SEND. Without this, tapping a reply
    // notification put its casama://app/bots/…/chat link into quick ask.
    final items = all.where((f) => f.type != SharedMediaType.url).toList();
    if (items.isEmpty) {
      if (all.isNotEmpty) ReceiveSharingIntent.instance.reset();
      return;
    }
    final (text, files) = splitSharedMedia(items);
    ref.read(pendingSharedFilesProvider.notifier).set(files);
    ref.read(routerProvider).go(Uri(path: '/quick-ask', queryParameters: {if (text.isNotEmpty) 'text': text}).toString());
    ReceiveSharingIntent.instance.reset();
  }

  final sub = ReceiveSharingIntent.instance.getMediaStream().listen(open, onError: (_) {});
  unawaited(ReceiveSharingIntent.instance.getInitialMedia().then(open).catchError((_) {}));
  ref.onDispose(sub.cancel);
});

/// Reads (and clears) text the iOS share extension left in the App Group.
Future<String> takeSharedText() async {
  if (!_ios) return '';
  try {
    await HomeWidget.setAppGroupId(appGroupId);
    final text = await HomeWidget.getWidgetData<String>('shared_text') ?? '';
    await HomeWidget.saveWidgetData<String>('shared_text', null);
    return text;
  } catch (_) {
    return '';
  }
}


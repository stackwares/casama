import 'package:casama_sdk/casama_sdk.dart';
import 'package:material_ui/material_ui.dart';

import 'widgets.dart';

/// The model-key providers as the add-key form and the model pickers show them (D-374): one list,
/// sent by the server in `/v1/config` (`key_providers`). The copy here is the fallback for servers
/// from before it. Ids this app doesn't know are skipped; a provider the server leaves out of both
/// form groups still lands under "More providers", so none is ever missing from the form.
class KeyProviders {
  const KeyProviders._({
    required this.chat,
    required this.more,
    required this.cloud,
    required this.runsChat,
    this.hints = const {},
  });

  /// Chat-model providers: what most people add a key for, listed first (D-182).
  final List<ProviderId> chat;

  /// Search, maps, data and a self-hosted server, under "More providers".
  final List<ProviderId> more;

  /// The only keys worth adding on Casama Cloud, which runs every model, voice and image itself
  /// (D-188). When it's empty, Settings hides the Service keys row.
  final List<ProviderId> cloud;

  /// Keys that run chat models; search, image and voice keys can't drive a bot.
  final Set<ProviderId> runsChat;

  /// The server's line under a provider's name; the app's own words when it sends none.
  final Map<ProviderId, String> hints;

  /// Keys added by pasting a key (a ChatGPT plan is connected by signing in instead).
  List<ProviderId> get all => [...chat, ...more];

  static const _chat = [
    ProviderId.openrouter,
    ProviderId.openai,
    ProviderId.anthropic,
    ProviderId.google,
    ProviderId.xai,
  ];
  static const _more = [
    ProviderId.braveSearch,
    ProviderId.tavily,
    ProviderId.parallel,
    ProviderId.serper,
    ProviderId.googleMaps,
    ProviderId.mapbox,
    ProviderId.treg,
    ProviderId.openaiCompatible,
  ];

  /// What the app shipped with: used when the server doesn't send the list.
  static final fallback = KeyProviders._(
    chat: _chat,
    more: _withRest(_more, _chat),
    cloud: const [
      ProviderId.braveSearch,
      ProviderId.tavily,
      ProviderId.googleMaps,
      ProviderId.mapbox,
      ProviderId.treg,
    ],
    runsChat: const {..._chat, ProviderId.openaiCompatible},
  );

  /// The server's list, read leniently: unknown ids are skipped, and a part that comes out empty
  /// (or a server without the list) uses the fallback's.
  factory KeyProviders.from(PublicConfigKeyProviders? remote) {
    if (remote == null) return fallback;
    List<ProviderId> ids(List<String> raw) => [
      for (final s in raw)
        if (_byValue[s] case final p? when p != ProviderId.chatgpt) p,
    ];
    final sentChat = ids(remote.chat);
    final chat = sentChat.isEmpty ? _chat : sentChat;
    final sentMore = ids(remote.more).where((p) => !chat.contains(p)).toList();
    final more = sentMore.isEmpty
        ? _more.where((p) => !chat.contains(p)).toList()
        : sentMore;
    final runsChat = ids(remote.runsChat).toSet();
    return KeyProviders._(
      chat: chat,
      more: _withRest(more, chat),
      // An empty cloud list means Casama Cloud supplies every key, so it's kept as sent.
      cloud: ids(remote.cloud),
      runsChat: runsChat.isEmpty ? fallback.runsChat : runsChat,
      hints: {
        for (final MapEntry(:key, :value)
            in (remote.hints ?? const <String, String>{}).entries)
          if (_byValue[key] case final p? when value.trim().isNotEmpty)
            p: value.trim(),
      },
    );
  }

  static final _byValue = {for (final p in ProviderId.values) p.value: p};

  /// [more] plus every provider in neither group, so a provider added later is never left out.
  static List<ProviderId> _withRest(
    List<ProviderId> more,
    List<ProviderId> chat,
  ) => [
    ...more,
    for (final p in ProviderId.values)
      if (p != ProviderId.chatgpt && !chat.contains(p) && !more.contains(p)) p,
  ];

  /// The line under [p]'s name: the server's words, else the app's own.
  String? hint(BuildContext context, ProviderId p) {
    if (hints[p] case final h?) return h;
    final l10n = context.l10n;
    return switch (p) {
      ProviderId.openrouter => l10n.providerHintOpenRouter,
      ProviderId.google => l10n.providerHintGoogle,
      ProviderId.openaiCompatible => l10n.providerHintCompatible,
      ProviderId.braveSearch ||
      ProviderId.tavily ||
      ProviderId.parallel ||
      ProviderId.serper => l10n.providerHintSearch,
      ProviderId.treg => l10n.providerHintData,
      ProviderId.googleMaps || ProviderId.mapbox => l10n.providerHintMaps,
      _ => null,
    };
  }
}

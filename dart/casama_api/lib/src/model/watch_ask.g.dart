// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_ask.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchAskCWProxy {
  WatchAsk botId(String botId);

  WatchAsk conversationId(String? conversationId);

  WatchAsk text(String? text);

  WatchAsk audio(WatchAudio? audio);

  WatchAsk language(String? language);

  WatchAsk askedAt(DateTime? askedAt);

  WatchAsk surface(WatchSurface? surface);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchAsk(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchAsk(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchAsk call({
    String botId,
    String? conversationId,
    String? text,
    WatchAudio? audio,
    String? language,
    DateTime? askedAt,
    WatchSurface? surface,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchAsk.copyWith(...)` or call `instanceOfWatchAsk.copyWith.fieldName(value)` for a single field.
class _$WatchAskCWProxyImpl implements _$WatchAskCWProxy {
  const _$WatchAskCWProxyImpl(this._value);

  final WatchAsk _value;

  @override
  WatchAsk botId(String botId) => call(botId: botId);

  @override
  WatchAsk conversationId(String? conversationId) =>
      call(conversationId: conversationId);

  @override
  WatchAsk text(String? text) => call(text: text);

  @override
  WatchAsk audio(WatchAudio? audio) => call(audio: audio);

  @override
  WatchAsk language(String? language) => call(language: language);

  @override
  WatchAsk askedAt(DateTime? askedAt) => call(askedAt: askedAt);

  @override
  WatchAsk surface(WatchSurface? surface) => call(surface: surface);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchAsk(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchAsk(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchAsk call({
    Object? botId = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
    Object? audio = const $CopyWithPlaceholder(),
    Object? language = const $CopyWithPlaceholder(),
    Object? askedAt = const $CopyWithPlaceholder(),
    Object? surface = const $CopyWithPlaceholder(),
  }) {
    return WatchAsk(
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      conversationId: conversationId == const $CopyWithPlaceholder()
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String?,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String?,
      audio: audio == const $CopyWithPlaceholder()
          ? _value.audio
          // ignore: cast_nullable_to_non_nullable
          : audio as WatchAudio?,
      language: language == const $CopyWithPlaceholder()
          ? _value.language
          // ignore: cast_nullable_to_non_nullable
          : language as String?,
      askedAt: askedAt == const $CopyWithPlaceholder()
          ? _value.askedAt
          // ignore: cast_nullable_to_non_nullable
          : askedAt as DateTime?,
      surface: surface == const $CopyWithPlaceholder()
          ? _value.surface
          // ignore: cast_nullable_to_non_nullable
          : surface as WatchSurface?,
    );
  }
}

extension $WatchAskCopyWith on WatchAsk {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchAsk.copyWith(...)` or `instanceOfWatchAsk.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchAskCWProxy get copyWith => _$WatchAskCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchAsk _$WatchAskFromJson(Map<String, dynamic> json) => $checkedCreate(
  'WatchAsk',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['bot_id']);
    final val = WatchAsk(
      botId: $checkedConvert('bot_id', (v) => v as String),
      conversationId: $checkedConvert('conversation_id', (v) => v as String?),
      text: $checkedConvert('text', (v) => v as String?),
      audio: $checkedConvert(
        'audio',
        (v) =>
            v == null ? null : WatchAudio.fromJson(v as Map<String, dynamic>),
      ),
      language: $checkedConvert('language', (v) => v as String?),
      askedAt: $checkedConvert(
        'asked_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      surface: $checkedConvert(
        'surface',
        (v) => $enumDecodeNullable(_$WatchSurfaceEnumMap, v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'conversationId': 'conversation_id',
    'askedAt': 'asked_at',
  },
);

Map<String, dynamic> _$WatchAskToJson(WatchAsk instance) => <String, dynamic>{
  'bot_id': instance.botId,
  'conversation_id': ?instance.conversationId,
  'text': ?instance.text,
  'audio': ?instance.audio?.toJson(),
  'language': ?instance.language,
  'asked_at': ?instance.askedAt?.toIso8601String(),
  'surface': ?_$WatchSurfaceEnumMap[instance.surface],
};

const _$WatchSurfaceEnumMap = {
  WatchSurface.app: 'app',
  WatchSurface.notification: 'notification',
  WatchSurface.complication: 'complication',
  WatchSurface.smartStack: 'smart_stack',
  WatchSurface.tile: 'tile',
  WatchSurface.control: 'control',
  WatchSurface.siri: 'siri',
};

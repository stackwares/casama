// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glance_brief.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GlanceBriefCWProxy {
  GlanceBrief botId(String botId);

  GlanceBrief bot(String bot);

  GlanceBrief botAvatar(String botAvatar);

  GlanceBrief text(String? text);

  GlanceBrief at(DateTime? at);

  GlanceBrief nextAt(DateTime? nextAt);

  GlanceBrief link(String link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceBrief(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceBrief(...).copyWith(id: 12, name: "My name")
  /// ```
  GlanceBrief call({
    String botId,
    String bot,
    String botAvatar,
    String? text,
    DateTime? at,
    DateTime? nextAt,
    String link,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGlanceBrief.copyWith(...)` or call `instanceOfGlanceBrief.copyWith.fieldName(value)` for a single field.
class _$GlanceBriefCWProxyImpl implements _$GlanceBriefCWProxy {
  const _$GlanceBriefCWProxyImpl(this._value);

  final GlanceBrief _value;

  @override
  GlanceBrief botId(String botId) => call(botId: botId);

  @override
  GlanceBrief bot(String bot) => call(bot: bot);

  @override
  GlanceBrief botAvatar(String botAvatar) => call(botAvatar: botAvatar);

  @override
  GlanceBrief text(String? text) => call(text: text);

  @override
  GlanceBrief at(DateTime? at) => call(at: at);

  @override
  GlanceBrief nextAt(DateTime? nextAt) => call(nextAt: nextAt);

  @override
  GlanceBrief link(String link) => call(link: link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceBrief(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceBrief(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GlanceBrief call({
    Object? botId = const $CopyWithPlaceholder(),
    Object? bot = const $CopyWithPlaceholder(),
    Object? botAvatar = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
    Object? at = const $CopyWithPlaceholder(),
    Object? nextAt = const $CopyWithPlaceholder(),
    Object? link = const $CopyWithPlaceholder(),
  }) {
    return GlanceBrief(
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      bot: bot == const $CopyWithPlaceholder() || bot == null
          ? _value.bot
          // ignore: cast_nullable_to_non_nullable
          : bot as String,
      botAvatar: botAvatar == const $CopyWithPlaceholder() || botAvatar == null
          ? _value.botAvatar
          // ignore: cast_nullable_to_non_nullable
          : botAvatar as String,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String?,
      at: at == const $CopyWithPlaceholder()
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as DateTime?,
      nextAt: nextAt == const $CopyWithPlaceholder()
          ? _value.nextAt
          // ignore: cast_nullable_to_non_nullable
          : nextAt as DateTime?,
      link: link == const $CopyWithPlaceholder() || link == null
          ? _value.link
          // ignore: cast_nullable_to_non_nullable
          : link as String,
    );
  }
}

extension $GlanceBriefCopyWith on GlanceBrief {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGlanceBrief.copyWith(...)` or `instanceOfGlanceBrief.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GlanceBriefCWProxy get copyWith => _$GlanceBriefCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlanceBrief _$GlanceBriefFromJson(Map<String, dynamic> json) => $checkedCreate(
  'GlanceBrief',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'bot_id',
        'bot',
        'bot_avatar',
        'text',
        'at',
        'next_at',
        'link',
      ],
    );
    final val = GlanceBrief(
      botId: $checkedConvert('bot_id', (v) => v as String),
      bot: $checkedConvert('bot', (v) => v as String),
      botAvatar: $checkedConvert('bot_avatar', (v) => v as String),
      text: $checkedConvert('text', (v) => v as String?),
      at: $checkedConvert(
        'at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      nextAt: $checkedConvert(
        'next_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      link: $checkedConvert('link', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'botAvatar': 'bot_avatar',
    'nextAt': 'next_at',
  },
);

Map<String, dynamic> _$GlanceBriefToJson(GlanceBrief instance) =>
    <String, dynamic>{
      'bot_id': instance.botId,
      'bot': instance.bot,
      'bot_avatar': instance.botAvatar,
      'text': instance.text,
      'at': instance.at?.toIso8601String(),
      'next_at': instance.nextAt?.toIso8601String(),
      'link': instance.link,
    };

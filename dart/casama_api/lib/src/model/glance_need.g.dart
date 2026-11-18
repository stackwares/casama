// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glance_need.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GlanceNeedCWProxy {
  GlanceNeed kind(GlanceNeedKindEnum kind);

  GlanceNeed id(String id);

  GlanceNeed botId(String botId);

  GlanceNeed bot(String bot);

  GlanceNeed botAvatar(String botAvatar);

  GlanceNeed text(String text);

  GlanceNeed risk(GlanceNeedRiskEnum? risk);

  GlanceNeed urgent(bool urgent);

  GlanceNeed createdAt(DateTime createdAt);

  GlanceNeed link(String link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceNeed(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceNeed(...).copyWith(id: 12, name: "My name")
  /// ```
  GlanceNeed call({
    GlanceNeedKindEnum kind,
    String id,
    String botId,
    String bot,
    String botAvatar,
    String text,
    GlanceNeedRiskEnum? risk,
    bool urgent,
    DateTime createdAt,
    String link,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGlanceNeed.copyWith(...)` or call `instanceOfGlanceNeed.copyWith.fieldName(value)` for a single field.
class _$GlanceNeedCWProxyImpl implements _$GlanceNeedCWProxy {
  const _$GlanceNeedCWProxyImpl(this._value);

  final GlanceNeed _value;

  @override
  GlanceNeed kind(GlanceNeedKindEnum kind) => call(kind: kind);

  @override
  GlanceNeed id(String id) => call(id: id);

  @override
  GlanceNeed botId(String botId) => call(botId: botId);

  @override
  GlanceNeed bot(String bot) => call(bot: bot);

  @override
  GlanceNeed botAvatar(String botAvatar) => call(botAvatar: botAvatar);

  @override
  GlanceNeed text(String text) => call(text: text);

  @override
  GlanceNeed risk(GlanceNeedRiskEnum? risk) => call(risk: risk);

  @override
  GlanceNeed urgent(bool urgent) => call(urgent: urgent);

  @override
  GlanceNeed createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  GlanceNeed link(String link) => call(link: link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceNeed(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceNeed(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GlanceNeed call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? bot = const $CopyWithPlaceholder(),
    Object? botAvatar = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
    Object? risk = const $CopyWithPlaceholder(),
    Object? urgent = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? link = const $CopyWithPlaceholder(),
  }) {
    return GlanceNeed(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as GlanceNeedKindEnum,
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
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
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
      risk: risk == const $CopyWithPlaceholder()
          ? _value.risk
          // ignore: cast_nullable_to_non_nullable
          : risk as GlanceNeedRiskEnum?,
      urgent: urgent == const $CopyWithPlaceholder() || urgent == null
          ? _value.urgent
          // ignore: cast_nullable_to_non_nullable
          : urgent as bool,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      link: link == const $CopyWithPlaceholder() || link == null
          ? _value.link
          // ignore: cast_nullable_to_non_nullable
          : link as String,
    );
  }
}

extension $GlanceNeedCopyWith on GlanceNeed {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGlanceNeed.copyWith(...)` or `instanceOfGlanceNeed.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GlanceNeedCWProxy get copyWith => _$GlanceNeedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlanceNeed _$GlanceNeedFromJson(Map<String, dynamic> json) => $checkedCreate(
  'GlanceNeed',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'kind',
        'id',
        'bot_id',
        'bot',
        'bot_avatar',
        'text',
        'risk',
        'urgent',
        'created_at',
        'link',
      ],
    );
    final val = GlanceNeed(
      kind: $checkedConvert(
        'kind',
        (v) => $enumDecode(_$GlanceNeedKindEnumEnumMap, v),
      ),
      id: $checkedConvert('id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      bot: $checkedConvert('bot', (v) => v as String),
      botAvatar: $checkedConvert('bot_avatar', (v) => v as String),
      text: $checkedConvert('text', (v) => v as String),
      risk: $checkedConvert(
        'risk',
        (v) => $enumDecodeNullable(_$GlanceNeedRiskEnumEnumMap, v),
      ),
      urgent: $checkedConvert('urgent', (v) => v as bool),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      link: $checkedConvert('link', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'botAvatar': 'bot_avatar',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$GlanceNeedToJson(GlanceNeed instance) =>
    <String, dynamic>{
      'kind': _$GlanceNeedKindEnumEnumMap[instance.kind]!,
      'id': instance.id,
      'bot_id': instance.botId,
      'bot': instance.bot,
      'bot_avatar': instance.botAvatar,
      'text': instance.text,
      'risk': _$GlanceNeedRiskEnumEnumMap[instance.risk],
      'urgent': instance.urgent,
      'created_at': instance.createdAt.toIso8601String(),
      'link': instance.link,
    };

const _$GlanceNeedKindEnumEnumMap = {
  GlanceNeedKindEnum.approval: 'approval',
  GlanceNeedKindEnum.takeover: 'takeover',
  GlanceNeedKindEnum.suggestion: 'suggestion',
};

const _$GlanceNeedRiskEnumEnumMap = {
  GlanceNeedRiskEnum.low: 'low',
  GlanceNeedRiskEnum.medium: 'medium',
  GlanceNeedRiskEnum.high: 'high',
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glance_bot.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GlanceBotCWProxy {
  GlanceBot id(String id);

  GlanceBot name(String name);

  GlanceBot avatar(String avatar);

  GlanceBot status(GlanceBotStatusEnum status);

  GlanceBot step(String? step);

  GlanceBot lastText(String? lastText);

  GlanceBot lastAt(DateTime? lastAt);

  GlanceBot busyAt(DateTime? busyAt);

  GlanceBot link(String link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceBot(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceBot(...).copyWith(id: 12, name: "My name")
  /// ```
  GlanceBot call({
    String id,
    String name,
    String avatar,
    GlanceBotStatusEnum status,
    String? step,
    String? lastText,
    DateTime? lastAt,
    DateTime? busyAt,
    String link,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGlanceBot.copyWith(...)` or call `instanceOfGlanceBot.copyWith.fieldName(value)` for a single field.
class _$GlanceBotCWProxyImpl implements _$GlanceBotCWProxy {
  const _$GlanceBotCWProxyImpl(this._value);

  final GlanceBot _value;

  @override
  GlanceBot id(String id) => call(id: id);

  @override
  GlanceBot name(String name) => call(name: name);

  @override
  GlanceBot avatar(String avatar) => call(avatar: avatar);

  @override
  GlanceBot status(GlanceBotStatusEnum status) => call(status: status);

  @override
  GlanceBot step(String? step) => call(step: step);

  @override
  GlanceBot lastText(String? lastText) => call(lastText: lastText);

  @override
  GlanceBot lastAt(DateTime? lastAt) => call(lastAt: lastAt);

  @override
  GlanceBot busyAt(DateTime? busyAt) => call(busyAt: busyAt);

  @override
  GlanceBot link(String link) => call(link: link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceBot(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceBot(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GlanceBot call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? avatar = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? step = const $CopyWithPlaceholder(),
    Object? lastText = const $CopyWithPlaceholder(),
    Object? lastAt = const $CopyWithPlaceholder(),
    Object? busyAt = const $CopyWithPlaceholder(),
    Object? link = const $CopyWithPlaceholder(),
  }) {
    return GlanceBot(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      avatar: avatar == const $CopyWithPlaceholder() || avatar == null
          ? _value.avatar
          // ignore: cast_nullable_to_non_nullable
          : avatar as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as GlanceBotStatusEnum,
      step: step == const $CopyWithPlaceholder()
          ? _value.step
          // ignore: cast_nullable_to_non_nullable
          : step as String?,
      lastText: lastText == const $CopyWithPlaceholder()
          ? _value.lastText
          // ignore: cast_nullable_to_non_nullable
          : lastText as String?,
      lastAt: lastAt == const $CopyWithPlaceholder()
          ? _value.lastAt
          // ignore: cast_nullable_to_non_nullable
          : lastAt as DateTime?,
      busyAt: busyAt == const $CopyWithPlaceholder()
          ? _value.busyAt
          // ignore: cast_nullable_to_non_nullable
          : busyAt as DateTime?,
      link: link == const $CopyWithPlaceholder() || link == null
          ? _value.link
          // ignore: cast_nullable_to_non_nullable
          : link as String,
    );
  }
}

extension $GlanceBotCopyWith on GlanceBot {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGlanceBot.copyWith(...)` or `instanceOfGlanceBot.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GlanceBotCWProxy get copyWith => _$GlanceBotCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlanceBot _$GlanceBotFromJson(Map<String, dynamic> json) => $checkedCreate(
  'GlanceBot',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'name',
        'avatar',
        'status',
        'step',
        'last_text',
        'last_at',
        'busy_at',
        'link',
      ],
    );
    final val = GlanceBot(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      avatar: $checkedConvert('avatar', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$GlanceBotStatusEnumEnumMap, v),
      ),
      step: $checkedConvert('step', (v) => v as String?),
      lastText: $checkedConvert('last_text', (v) => v as String?),
      lastAt: $checkedConvert(
        'last_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      busyAt: $checkedConvert(
        'busy_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      link: $checkedConvert('link', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'lastText': 'last_text',
    'lastAt': 'last_at',
    'busyAt': 'busy_at',
  },
);

Map<String, dynamic> _$GlanceBotToJson(GlanceBot instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'avatar': instance.avatar,
  'status': _$GlanceBotStatusEnumEnumMap[instance.status]!,
  'step': instance.step,
  'last_text': instance.lastText,
  'last_at': instance.lastAt?.toIso8601String(),
  'busy_at': instance.busyAt?.toIso8601String(),
  'link': instance.link,
};

const _$GlanceBotStatusEnumEnumMap = {
  GlanceBotStatusEnum.idle: 'idle',
  GlanceBotStatusEnum.working: 'working',
  GlanceBotStatusEnum.waiting: 'waiting',
  GlanceBotStatusEnum.disabled: 'disabled',
};

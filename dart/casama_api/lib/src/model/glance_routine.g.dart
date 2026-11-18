// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glance_routine.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GlanceRoutineCWProxy {
  GlanceRoutine id(String id);

  GlanceRoutine botId(String botId);

  GlanceRoutine name(String name);

  GlanceRoutine bot(String bot);

  GlanceRoutine botAvatar(String botAvatar);

  GlanceRoutine nextAt(DateTime? nextAt);

  GlanceRoutine every(String every);

  GlanceRoutine enabled(bool enabled);

  GlanceRoutine link(String link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceRoutine(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceRoutine(...).copyWith(id: 12, name: "My name")
  /// ```
  GlanceRoutine call({
    String id,
    String botId,
    String name,
    String bot,
    String botAvatar,
    DateTime? nextAt,
    String every,
    bool enabled,
    String link,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGlanceRoutine.copyWith(...)` or call `instanceOfGlanceRoutine.copyWith.fieldName(value)` for a single field.
class _$GlanceRoutineCWProxyImpl implements _$GlanceRoutineCWProxy {
  const _$GlanceRoutineCWProxyImpl(this._value);

  final GlanceRoutine _value;

  @override
  GlanceRoutine id(String id) => call(id: id);

  @override
  GlanceRoutine botId(String botId) => call(botId: botId);

  @override
  GlanceRoutine name(String name) => call(name: name);

  @override
  GlanceRoutine bot(String bot) => call(bot: bot);

  @override
  GlanceRoutine botAvatar(String botAvatar) => call(botAvatar: botAvatar);

  @override
  GlanceRoutine nextAt(DateTime? nextAt) => call(nextAt: nextAt);

  @override
  GlanceRoutine every(String every) => call(every: every);

  @override
  GlanceRoutine enabled(bool enabled) => call(enabled: enabled);

  @override
  GlanceRoutine link(String link) => call(link: link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceRoutine(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceRoutine(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GlanceRoutine call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? bot = const $CopyWithPlaceholder(),
    Object? botAvatar = const $CopyWithPlaceholder(),
    Object? nextAt = const $CopyWithPlaceholder(),
    Object? every = const $CopyWithPlaceholder(),
    Object? enabled = const $CopyWithPlaceholder(),
    Object? link = const $CopyWithPlaceholder(),
  }) {
    return GlanceRoutine(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      bot: bot == const $CopyWithPlaceholder() || bot == null
          ? _value.bot
          // ignore: cast_nullable_to_non_nullable
          : bot as String,
      botAvatar: botAvatar == const $CopyWithPlaceholder() || botAvatar == null
          ? _value.botAvatar
          // ignore: cast_nullable_to_non_nullable
          : botAvatar as String,
      nextAt: nextAt == const $CopyWithPlaceholder()
          ? _value.nextAt
          // ignore: cast_nullable_to_non_nullable
          : nextAt as DateTime?,
      every: every == const $CopyWithPlaceholder() || every == null
          ? _value.every
          // ignore: cast_nullable_to_non_nullable
          : every as String,
      enabled: enabled == const $CopyWithPlaceholder() || enabled == null
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
      link: link == const $CopyWithPlaceholder() || link == null
          ? _value.link
          // ignore: cast_nullable_to_non_nullable
          : link as String,
    );
  }
}

extension $GlanceRoutineCopyWith on GlanceRoutine {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGlanceRoutine.copyWith(...)` or `instanceOfGlanceRoutine.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GlanceRoutineCWProxy get copyWith => _$GlanceRoutineCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlanceRoutine _$GlanceRoutineFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'GlanceRoutine',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'bot_id',
            'name',
            'bot',
            'bot_avatar',
            'next_at',
            'every',
            'enabled',
            'link',
          ],
        );
        final val = GlanceRoutine(
          id: $checkedConvert('id', (v) => v as String),
          botId: $checkedConvert('bot_id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          bot: $checkedConvert('bot', (v) => v as String),
          botAvatar: $checkedConvert('bot_avatar', (v) => v as String),
          nextAt: $checkedConvert(
            'next_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          every: $checkedConvert('every', (v) => v as String),
          enabled: $checkedConvert('enabled', (v) => v as bool),
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

Map<String, dynamic> _$GlanceRoutineToJson(GlanceRoutine instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bot_id': instance.botId,
      'name': instance.name,
      'bot': instance.bot,
      'bot_avatar': instance.botAvatar,
      'next_at': instance.nextAt?.toIso8601String(),
      'every': instance.every,
      'enabled': instance.enabled,
      'link': instance.link,
    };

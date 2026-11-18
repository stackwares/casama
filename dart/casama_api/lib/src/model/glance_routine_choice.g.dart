// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glance_routine_choice.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GlanceRoutineChoiceCWProxy {
  GlanceRoutineChoice id(String id);

  GlanceRoutineChoice botId(String botId);

  GlanceRoutineChoice name(String name);

  GlanceRoutineChoice bot(String bot);

  GlanceRoutineChoice enabled(bool enabled);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceRoutineChoice(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceRoutineChoice(...).copyWith(id: 12, name: "My name")
  /// ```
  GlanceRoutineChoice call({
    String id,
    String botId,
    String name,
    String bot,
    bool enabled,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGlanceRoutineChoice.copyWith(...)` or call `instanceOfGlanceRoutineChoice.copyWith.fieldName(value)` for a single field.
class _$GlanceRoutineChoiceCWProxyImpl implements _$GlanceRoutineChoiceCWProxy {
  const _$GlanceRoutineChoiceCWProxyImpl(this._value);

  final GlanceRoutineChoice _value;

  @override
  GlanceRoutineChoice id(String id) => call(id: id);

  @override
  GlanceRoutineChoice botId(String botId) => call(botId: botId);

  @override
  GlanceRoutineChoice name(String name) => call(name: name);

  @override
  GlanceRoutineChoice bot(String bot) => call(bot: bot);

  @override
  GlanceRoutineChoice enabled(bool enabled) => call(enabled: enabled);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceRoutineChoice(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceRoutineChoice(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GlanceRoutineChoice call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? bot = const $CopyWithPlaceholder(),
    Object? enabled = const $CopyWithPlaceholder(),
  }) {
    return GlanceRoutineChoice(
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
      enabled: enabled == const $CopyWithPlaceholder() || enabled == null
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
    );
  }
}

extension $GlanceRoutineChoiceCopyWith on GlanceRoutineChoice {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGlanceRoutineChoice.copyWith(...)` or `instanceOfGlanceRoutineChoice.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GlanceRoutineChoiceCWProxy get copyWith =>
      _$GlanceRoutineChoiceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlanceRoutineChoice _$GlanceRoutineChoiceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GlanceRoutineChoice', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['id', 'bot_id', 'name', 'bot', 'enabled'],
      );
      final val = GlanceRoutineChoice(
        id: $checkedConvert('id', (v) => v as String),
        botId: $checkedConvert('bot_id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        bot: $checkedConvert('bot', (v) => v as String),
        enabled: $checkedConvert('enabled', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'botId': 'bot_id'});

Map<String, dynamic> _$GlanceRoutineChoiceToJson(
  GlanceRoutineChoice instance,
) => <String, dynamic>{
  'id': instance.id,
  'bot_id': instance.botId,
  'name': instance.name,
  'bot': instance.bot,
  'enabled': instance.enabled,
};

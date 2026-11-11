// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_template_file_routines_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotTemplateFileRoutinesInnerCWProxy {
  BotTemplateFileRoutinesInner name(String name);

  BotTemplateFileRoutinesInner instructionsMd(String instructionsMd);

  BotTemplateFileRoutinesInner scheduleCron(String scheduleCron);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotTemplateFileRoutinesInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotTemplateFileRoutinesInner(...).copyWith(id: 12, name: "My name")
  /// ```
  BotTemplateFileRoutinesInner call({
    String name,
    String instructionsMd,
    String scheduleCron,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotTemplateFileRoutinesInner.copyWith(...)` or call `instanceOfBotTemplateFileRoutinesInner.copyWith.fieldName(value)` for a single field.
class _$BotTemplateFileRoutinesInnerCWProxyImpl
    implements _$BotTemplateFileRoutinesInnerCWProxy {
  const _$BotTemplateFileRoutinesInnerCWProxyImpl(this._value);

  final BotTemplateFileRoutinesInner _value;

  @override
  BotTemplateFileRoutinesInner name(String name) => call(name: name);

  @override
  BotTemplateFileRoutinesInner instructionsMd(String instructionsMd) =>
      call(instructionsMd: instructionsMd);

  @override
  BotTemplateFileRoutinesInner scheduleCron(String scheduleCron) =>
      call(scheduleCron: scheduleCron);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotTemplateFileRoutinesInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotTemplateFileRoutinesInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotTemplateFileRoutinesInner call({
    Object? name = const $CopyWithPlaceholder(),
    Object? instructionsMd = const $CopyWithPlaceholder(),
    Object? scheduleCron = const $CopyWithPlaceholder(),
  }) {
    return BotTemplateFileRoutinesInner(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      instructionsMd:
          instructionsMd == const $CopyWithPlaceholder() ||
              instructionsMd == null
          ? _value.instructionsMd
          // ignore: cast_nullable_to_non_nullable
          : instructionsMd as String,
      scheduleCron:
          scheduleCron == const $CopyWithPlaceholder() || scheduleCron == null
          ? _value.scheduleCron
          // ignore: cast_nullable_to_non_nullable
          : scheduleCron as String,
    );
  }
}

extension $BotTemplateFileRoutinesInnerCopyWith
    on BotTemplateFileRoutinesInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotTemplateFileRoutinesInner.copyWith(...)` or `instanceOfBotTemplateFileRoutinesInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotTemplateFileRoutinesInnerCWProxy get copyWith =>
      _$BotTemplateFileRoutinesInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotTemplateFileRoutinesInner _$BotTemplateFileRoutinesInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'BotTemplateFileRoutinesInner',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['name', 'instructions_md', 'schedule_cron'],
    );
    final val = BotTemplateFileRoutinesInner(
      name: $checkedConvert('name', (v) => v as String),
      instructionsMd: $checkedConvert('instructions_md', (v) => v as String),
      scheduleCron: $checkedConvert('schedule_cron', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'instructionsMd': 'instructions_md',
    'scheduleCron': 'schedule_cron',
  },
);

Map<String, dynamic> _$BotTemplateFileRoutinesInnerToJson(
  BotTemplateFileRoutinesInner instance,
) => <String, dynamic>{
  'name': instance.name,
  'instructions_md': instance.instructionsMd,
  'schedule_cron': instance.scheduleCron,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_routine_preview.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackRoutinePreviewCWProxy {
  PackRoutinePreview id(String id);

  PackRoutinePreview name(String name);

  PackRoutinePreview description(String description);

  PackRoutinePreview instructionsMd(String instructionsMd);

  PackRoutinePreview scheduleCron(String scheduleCron);

  PackRoutinePreview bot(String? bot);

  PackRoutinePreview runsPerWeek(num runsPerWeek);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackRoutinePreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackRoutinePreview(...).copyWith(id: 12, name: "My name")
  /// ```
  PackRoutinePreview call({
    String id,
    String name,
    String description,
    String instructionsMd,
    String scheduleCron,
    String? bot,
    num runsPerWeek,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackRoutinePreview.copyWith(...)` or call `instanceOfPackRoutinePreview.copyWith.fieldName(value)` for a single field.
class _$PackRoutinePreviewCWProxyImpl implements _$PackRoutinePreviewCWProxy {
  const _$PackRoutinePreviewCWProxyImpl(this._value);

  final PackRoutinePreview _value;

  @override
  PackRoutinePreview id(String id) => call(id: id);

  @override
  PackRoutinePreview name(String name) => call(name: name);

  @override
  PackRoutinePreview description(String description) =>
      call(description: description);

  @override
  PackRoutinePreview instructionsMd(String instructionsMd) =>
      call(instructionsMd: instructionsMd);

  @override
  PackRoutinePreview scheduleCron(String scheduleCron) =>
      call(scheduleCron: scheduleCron);

  @override
  PackRoutinePreview bot(String? bot) => call(bot: bot);

  @override
  PackRoutinePreview runsPerWeek(num runsPerWeek) =>
      call(runsPerWeek: runsPerWeek);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackRoutinePreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackRoutinePreview(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackRoutinePreview call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? instructionsMd = const $CopyWithPlaceholder(),
    Object? scheduleCron = const $CopyWithPlaceholder(),
    Object? bot = const $CopyWithPlaceholder(),
    Object? runsPerWeek = const $CopyWithPlaceholder(),
  }) {
    return PackRoutinePreview(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
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
      bot: bot == const $CopyWithPlaceholder()
          ? _value.bot
          // ignore: cast_nullable_to_non_nullable
          : bot as String?,
      runsPerWeek:
          runsPerWeek == const $CopyWithPlaceholder() || runsPerWeek == null
          ? _value.runsPerWeek
          // ignore: cast_nullable_to_non_nullable
          : runsPerWeek as num,
    );
  }
}

extension $PackRoutinePreviewCopyWith on PackRoutinePreview {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackRoutinePreview.copyWith(...)` or `instanceOfPackRoutinePreview.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackRoutinePreviewCWProxy get copyWith =>
      _$PackRoutinePreviewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackRoutinePreview _$PackRoutinePreviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PackRoutinePreview',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'name',
            'description',
            'instructions_md',
            'schedule_cron',
            'bot',
            'runs_per_week',
          ],
        );
        final val = PackRoutinePreview(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          instructionsMd: $checkedConvert(
            'instructions_md',
            (v) => v as String,
          ),
          scheduleCron: $checkedConvert('schedule_cron', (v) => v as String),
          bot: $checkedConvert('bot', (v) => v as String?),
          runsPerWeek: $checkedConvert('runs_per_week', (v) => v as num),
        );
        return val;
      },
      fieldKeyMap: const {
        'instructionsMd': 'instructions_md',
        'scheduleCron': 'schedule_cron',
        'runsPerWeek': 'runs_per_week',
      },
    );

Map<String, dynamic> _$PackRoutinePreviewToJson(PackRoutinePreview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'instructions_md': instance.instructionsMd,
      'schedule_cron': instance.scheduleCron,
      'bot': instance.bot,
      'runs_per_week': instance.runsPerWeek,
    };

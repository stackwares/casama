// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_routines_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TemplateRoutinesInnerCWProxy {
  TemplateRoutinesInner name(String name);

  TemplateRoutinesInner scheduleCron(String scheduleCron);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TemplateRoutinesInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TemplateRoutinesInner(...).copyWith(id: 12, name: "My name")
  /// ```
  TemplateRoutinesInner call({String name, String scheduleCron});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTemplateRoutinesInner.copyWith(...)` or call `instanceOfTemplateRoutinesInner.copyWith.fieldName(value)` for a single field.
class _$TemplateRoutinesInnerCWProxyImpl
    implements _$TemplateRoutinesInnerCWProxy {
  const _$TemplateRoutinesInnerCWProxyImpl(this._value);

  final TemplateRoutinesInner _value;

  @override
  TemplateRoutinesInner name(String name) => call(name: name);

  @override
  TemplateRoutinesInner scheduleCron(String scheduleCron) =>
      call(scheduleCron: scheduleCron);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TemplateRoutinesInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TemplateRoutinesInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TemplateRoutinesInner call({
    Object? name = const $CopyWithPlaceholder(),
    Object? scheduleCron = const $CopyWithPlaceholder(),
  }) {
    return TemplateRoutinesInner(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      scheduleCron:
          scheduleCron == const $CopyWithPlaceholder() || scheduleCron == null
          ? _value.scheduleCron
          // ignore: cast_nullable_to_non_nullable
          : scheduleCron as String,
    );
  }
}

extension $TemplateRoutinesInnerCopyWith on TemplateRoutinesInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTemplateRoutinesInner.copyWith(...)` or `instanceOfTemplateRoutinesInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TemplateRoutinesInnerCWProxy get copyWith =>
      _$TemplateRoutinesInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TemplateRoutinesInner _$TemplateRoutinesInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('TemplateRoutinesInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name', 'schedule_cron']);
  final val = TemplateRoutinesInner(
    name: $checkedConvert('name', (v) => v as String),
    scheduleCron: $checkedConvert('schedule_cron', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'scheduleCron': 'schedule_cron'});

Map<String, dynamic> _$TemplateRoutinesInnerToJson(
  TemplateRoutinesInner instance,
) => <String, dynamic>{
  'name': instance.name,
  'schedule_cron': instance.scheduleCron,
};

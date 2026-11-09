// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_routines_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TemplateRoutinesInnerCWProxy {
  TemplateRoutinesInner name(String name);

  TemplateRoutinesInner scheduleCron(String scheduleCron);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TemplateRoutinesInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TemplateRoutinesInner(...).copyWith(id: 12, name: "My name")
  /// ````
  TemplateRoutinesInner call({String name, String scheduleCron});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTemplateRoutinesInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTemplateRoutinesInner.copyWith.fieldName(...)`
class _$TemplateRoutinesInnerCWProxyImpl
    implements _$TemplateRoutinesInnerCWProxy {
  const _$TemplateRoutinesInnerCWProxyImpl(this._value);

  final TemplateRoutinesInner _value;

  @override
  TemplateRoutinesInner name(String name) => this(name: name);

  @override
  TemplateRoutinesInner scheduleCron(String scheduleCron) =>
      this(scheduleCron: scheduleCron);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TemplateRoutinesInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TemplateRoutinesInner(...).copyWith(id: 12, name: "My name")
  /// ````
  TemplateRoutinesInner call({
    Object? name = const $CopyWithPlaceholder(),
    Object? scheduleCron = const $CopyWithPlaceholder(),
  }) {
    return TemplateRoutinesInner(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      scheduleCron: scheduleCron == const $CopyWithPlaceholder()
          ? _value.scheduleCron
          // ignore: cast_nullable_to_non_nullable
          : scheduleCron as String,
    );
  }
}

extension $TemplateRoutinesInnerCopyWith on TemplateRoutinesInner {
  /// Returns a callable class that can be used as follows: `instanceOfTemplateRoutinesInner.copyWith(...)` or like so:`instanceOfTemplateRoutinesInner.copyWith.fieldName(...)`.
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

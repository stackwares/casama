// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TemplateCWProxy {
  Template id(String id);

  Template name(String name);

  Template description(String description);

  Template autonomy(TemplateAutonomyEnum autonomy);

  Template skills(List<String> skills);

  Template routines(List<TemplateRoutinesInner> routines);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Template(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Template(...).copyWith(id: 12, name: "My name")
  /// ````
  Template call({
    String id,
    String name,
    String description,
    TemplateAutonomyEnum autonomy,
    List<String> skills,
    List<TemplateRoutinesInner> routines,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTemplate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTemplate.copyWith.fieldName(...)`
class _$TemplateCWProxyImpl implements _$TemplateCWProxy {
  const _$TemplateCWProxyImpl(this._value);

  final Template _value;

  @override
  Template id(String id) => this(id: id);

  @override
  Template name(String name) => this(name: name);

  @override
  Template description(String description) => this(description: description);

  @override
  Template autonomy(TemplateAutonomyEnum autonomy) => this(autonomy: autonomy);

  @override
  Template skills(List<String> skills) => this(skills: skills);

  @override
  Template routines(List<TemplateRoutinesInner> routines) =>
      this(routines: routines);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Template(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Template(...).copyWith(id: 12, name: "My name")
  /// ````
  Template call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? autonomy = const $CopyWithPlaceholder(),
    Object? skills = const $CopyWithPlaceholder(),
    Object? routines = const $CopyWithPlaceholder(),
  }) {
    return Template(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      autonomy: autonomy == const $CopyWithPlaceholder()
          ? _value.autonomy
          // ignore: cast_nullable_to_non_nullable
          : autonomy as TemplateAutonomyEnum,
      skills: skills == const $CopyWithPlaceholder()
          ? _value.skills
          // ignore: cast_nullable_to_non_nullable
          : skills as List<String>,
      routines: routines == const $CopyWithPlaceholder()
          ? _value.routines
          // ignore: cast_nullable_to_non_nullable
          : routines as List<TemplateRoutinesInner>,
    );
  }
}

extension $TemplateCopyWith on Template {
  /// Returns a callable class that can be used as follows: `instanceOfTemplate.copyWith(...)` or like so:`instanceOfTemplate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TemplateCWProxy get copyWith => _$TemplateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Template _$TemplateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Template', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'name',
          'description',
          'autonomy',
          'skills',
          'routines',
        ],
      );
      final val = Template(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String),
        autonomy: $checkedConvert(
          'autonomy',
          (v) => $enumDecode(_$TemplateAutonomyEnumEnumMap, v),
        ),
        skills: $checkedConvert(
          'skills',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        routines: $checkedConvert(
          'routines',
          (v) => (v as List<dynamic>)
              .map(
                (e) =>
                    TemplateRoutinesInner.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TemplateToJson(Template instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'autonomy': _$TemplateAutonomyEnumEnumMap[instance.autonomy]!,
  'skills': instance.skills,
  'routines': instance.routines.map((e) => e.toJson()).toList(),
};

const _$TemplateAutonomyEnumEnumMap = {
  TemplateAutonomyEnum.askAlways: 'ask_always',
  TemplateAutonomyEnum.askRisky: 'ask_risky',
  TemplateAutonomyEnum.autonomous: 'autonomous',
};

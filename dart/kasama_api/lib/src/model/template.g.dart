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

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Template(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Template(...).copyWith(id: 12, name: "My name")
  /// ```
  Template call({
    String id,
    String name,
    String description,
    TemplateAutonomyEnum autonomy,
    List<String> skills,
    List<TemplateRoutinesInner> routines,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTemplate.copyWith(...)` or call `instanceOfTemplate.copyWith.fieldName(value)` for a single field.
class _$TemplateCWProxyImpl implements _$TemplateCWProxy {
  const _$TemplateCWProxyImpl(this._value);

  final Template _value;

  @override
  Template id(String id) => call(id: id);

  @override
  Template name(String name) => call(name: name);

  @override
  Template description(String description) => call(description: description);

  @override
  Template autonomy(TemplateAutonomyEnum autonomy) => call(autonomy: autonomy);

  @override
  Template skills(List<String> skills) => call(skills: skills);

  @override
  Template routines(List<TemplateRoutinesInner> routines) =>
      call(routines: routines);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Template(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Template(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Template call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? autonomy = const $CopyWithPlaceholder(),
    Object? skills = const $CopyWithPlaceholder(),
    Object? routines = const $CopyWithPlaceholder(),
  }) {
    return Template(
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
      autonomy: autonomy == const $CopyWithPlaceholder() || autonomy == null
          ? _value.autonomy
          // ignore: cast_nullable_to_non_nullable
          : autonomy as TemplateAutonomyEnum,
      skills: skills == const $CopyWithPlaceholder() || skills == null
          ? _value.skills
          // ignore: cast_nullable_to_non_nullable
          : skills as List<String>,
      routines: routines == const $CopyWithPlaceholder() || routines == null
          ? _value.routines
          // ignore: cast_nullable_to_non_nullable
          : routines as List<TemplateRoutinesInner>,
    );
  }
}

extension $TemplateCopyWith on Template {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTemplate.copyWith(...)` or `instanceOfTemplate.copyWith.fieldName(...)`.
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

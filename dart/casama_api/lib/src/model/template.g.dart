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

  Template persona(String? persona);

  Template category(TemplateCategoryEnum? category);

  Template icon(String? icon);

  Template mascot(String? mascot);

  Template starters(List<String>? starters);

  Template author(TemplateAuthor? author);

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
    String? persona,
    TemplateCategoryEnum? category,
    String? icon,
    String? mascot,
    List<String>? starters,
    TemplateAuthor? author,
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

  @override
  Template persona(String? persona) => call(persona: persona);

  @override
  Template category(TemplateCategoryEnum? category) => call(category: category);

  @override
  Template icon(String? icon) => call(icon: icon);

  @override
  Template mascot(String? mascot) => call(mascot: mascot);

  @override
  Template starters(List<String>? starters) => call(starters: starters);

  @override
  Template author(TemplateAuthor? author) => call(author: author);

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
    Object? persona = const $CopyWithPlaceholder(),
    Object? category = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? mascot = const $CopyWithPlaceholder(),
    Object? starters = const $CopyWithPlaceholder(),
    Object? author = const $CopyWithPlaceholder(),
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
      persona: persona == const $CopyWithPlaceholder()
          ? _value.persona
          // ignore: cast_nullable_to_non_nullable
          : persona as String?,
      category: category == const $CopyWithPlaceholder()
          ? _value.category
          // ignore: cast_nullable_to_non_nullable
          : category as TemplateCategoryEnum?,
      icon: icon == const $CopyWithPlaceholder()
          ? _value.icon
          // ignore: cast_nullable_to_non_nullable
          : icon as String?,
      mascot: mascot == const $CopyWithPlaceholder()
          ? _value.mascot
          // ignore: cast_nullable_to_non_nullable
          : mascot as String?,
      starters: starters == const $CopyWithPlaceholder()
          ? _value.starters
          // ignore: cast_nullable_to_non_nullable
          : starters as List<String>?,
      author: author == const $CopyWithPlaceholder()
          ? _value.author
          // ignore: cast_nullable_to_non_nullable
          : author as TemplateAuthor?,
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

Template _$TemplateFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('Template', json, ($checkedConvert) {
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
          .map((e) => TemplateRoutinesInner.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    persona: $checkedConvert('persona', (v) => v as String?),
    category: $checkedConvert(
      'category',
      (v) => $enumDecodeNullable(_$TemplateCategoryEnumEnumMap, v),
    ),
    icon: $checkedConvert('icon', (v) => v as String?),
    mascot: $checkedConvert('mascot', (v) => v as String?),
    starters: $checkedConvert(
      'starters',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
    ),
    author: $checkedConvert(
      'author',
      (v) =>
          v == null ? null : TemplateAuthor.fromJson(v as Map<String, dynamic>),
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
  'persona': ?instance.persona,
  'category': ?_$TemplateCategoryEnumEnumMap[instance.category],
  'icon': ?instance.icon,
  'mascot': ?instance.mascot,
  'starters': ?instance.starters,
  'author': ?instance.author?.toJson(),
};

const _$TemplateAutonomyEnumEnumMap = {
  TemplateAutonomyEnum.askAlways: 'ask_always',
  TemplateAutonomyEnum.askRisky: 'ask_risky',
  TemplateAutonomyEnum.autonomous: 'autonomous',
};

const _$TemplateCategoryEnumEnumMap = {
  TemplateCategoryEnum.work: 'work',
  TemplateCategoryEnum.research: 'research',
  TemplateCategoryEnum.build: 'build',
  TemplateCategoryEnum.create: 'create',
  TemplateCategoryEnum.life: 'life',
};

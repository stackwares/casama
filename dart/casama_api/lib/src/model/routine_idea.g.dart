// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_idea.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RoutineIdeaCWProxy {
  RoutineIdea id(String id);

  RoutineIdea name(String name);

  RoutineIdea description(String description);

  RoutineIdea category(RoutineIdeaCategoryEnum category);

  RoutineIdea icon(String icon);

  RoutineIdea instructionsMd(String instructionsMd);

  RoutineIdea scheduleCron(String scheduleCron);

  RoutineIdea featured(bool featured);

  RoutineIdea author(ContentAuthor author);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RoutineIdea(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RoutineIdea(...).copyWith(id: 12, name: "My name")
  /// ```
  RoutineIdea call({
    String id,
    String name,
    String description,
    RoutineIdeaCategoryEnum category,
    String icon,
    String instructionsMd,
    String scheduleCron,
    bool featured,
    ContentAuthor author,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRoutineIdea.copyWith(...)` or call `instanceOfRoutineIdea.copyWith.fieldName(value)` for a single field.
class _$RoutineIdeaCWProxyImpl implements _$RoutineIdeaCWProxy {
  const _$RoutineIdeaCWProxyImpl(this._value);

  final RoutineIdea _value;

  @override
  RoutineIdea id(String id) => call(id: id);

  @override
  RoutineIdea name(String name) => call(name: name);

  @override
  RoutineIdea description(String description) => call(description: description);

  @override
  RoutineIdea category(RoutineIdeaCategoryEnum category) =>
      call(category: category);

  @override
  RoutineIdea icon(String icon) => call(icon: icon);

  @override
  RoutineIdea instructionsMd(String instructionsMd) =>
      call(instructionsMd: instructionsMd);

  @override
  RoutineIdea scheduleCron(String scheduleCron) =>
      call(scheduleCron: scheduleCron);

  @override
  RoutineIdea featured(bool featured) => call(featured: featured);

  @override
  RoutineIdea author(ContentAuthor author) => call(author: author);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RoutineIdea(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RoutineIdea(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RoutineIdea call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? category = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? instructionsMd = const $CopyWithPlaceholder(),
    Object? scheduleCron = const $CopyWithPlaceholder(),
    Object? featured = const $CopyWithPlaceholder(),
    Object? author = const $CopyWithPlaceholder(),
  }) {
    return RoutineIdea(
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
      category: category == const $CopyWithPlaceholder() || category == null
          ? _value.category
          // ignore: cast_nullable_to_non_nullable
          : category as RoutineIdeaCategoryEnum,
      icon: icon == const $CopyWithPlaceholder() || icon == null
          ? _value.icon
          // ignore: cast_nullable_to_non_nullable
          : icon as String,
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
      featured: featured == const $CopyWithPlaceholder() || featured == null
          ? _value.featured
          // ignore: cast_nullable_to_non_nullable
          : featured as bool,
      author: author == const $CopyWithPlaceholder() || author == null
          ? _value.author
          // ignore: cast_nullable_to_non_nullable
          : author as ContentAuthor,
    );
  }
}

extension $RoutineIdeaCopyWith on RoutineIdea {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRoutineIdea.copyWith(...)` or `instanceOfRoutineIdea.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RoutineIdeaCWProxy get copyWith => _$RoutineIdeaCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoutineIdea _$RoutineIdeaFromJson(Map<String, dynamic> json) => $checkedCreate(
  'RoutineIdea',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'name',
        'description',
        'category',
        'icon',
        'instructions_md',
        'schedule_cron',
        'featured',
        'author',
      ],
    );
    final val = RoutineIdea(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      description: $checkedConvert('description', (v) => v as String),
      category: $checkedConvert(
        'category',
        (v) => $enumDecode(_$RoutineIdeaCategoryEnumEnumMap, v),
      ),
      icon: $checkedConvert('icon', (v) => v as String),
      instructionsMd: $checkedConvert('instructions_md', (v) => v as String),
      scheduleCron: $checkedConvert('schedule_cron', (v) => v as String),
      featured: $checkedConvert('featured', (v) => v as bool),
      author: $checkedConvert(
        'author',
        (v) => ContentAuthor.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'instructionsMd': 'instructions_md',
    'scheduleCron': 'schedule_cron',
  },
);

Map<String, dynamic> _$RoutineIdeaToJson(RoutineIdea instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category': _$RoutineIdeaCategoryEnumEnumMap[instance.category]!,
      'icon': instance.icon,
      'instructions_md': instance.instructionsMd,
      'schedule_cron': instance.scheduleCron,
      'featured': instance.featured,
      'author': instance.author.toJson(),
    };

const _$RoutineIdeaCategoryEnumEnumMap = {
  RoutineIdeaCategoryEnum.work: 'work',
  RoutineIdeaCategoryEnum.research: 'research',
  RoutineIdeaCategoryEnum.build: 'build',
  RoutineIdeaCategoryEnum.create: 'create',
  RoutineIdeaCategoryEnum.life: 'life',
};

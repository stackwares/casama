// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_bot_preview.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackBotPreviewCWProxy {
  PackBotPreview id(String id);

  PackBotPreview name(String name);

  PackBotPreview description(String description);

  PackBotPreview icon(String icon);

  PackBotPreview mascot(String mascot);

  PackBotPreview autonomy(PackBotPreviewAutonomyEnum autonomy);

  PackBotPreview persona(String persona);

  PackBotPreview starters(List<String> starters);

  PackBotPreview skills(List<String> skills);

  PackBotPreview routines(List<String> routines);

  PackBotPreview tools(List<String> tools);

  PackBotPreview rules(List<PackBotPreviewRulesInner>? rules);

  PackBotPreview knowledge(List<PackBotPreviewKnowledgeInner>? knowledge);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackBotPreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackBotPreview(...).copyWith(id: 12, name: "My name")
  /// ```
  PackBotPreview call({
    String id,
    String name,
    String description,
    String icon,
    String mascot,
    PackBotPreviewAutonomyEnum autonomy,
    String persona,
    List<String> starters,
    List<String> skills,
    List<String> routines,
    List<String> tools,
    List<PackBotPreviewRulesInner>? rules,
    List<PackBotPreviewKnowledgeInner>? knowledge,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackBotPreview.copyWith(...)` or call `instanceOfPackBotPreview.copyWith.fieldName(value)` for a single field.
class _$PackBotPreviewCWProxyImpl implements _$PackBotPreviewCWProxy {
  const _$PackBotPreviewCWProxyImpl(this._value);

  final PackBotPreview _value;

  @override
  PackBotPreview id(String id) => call(id: id);

  @override
  PackBotPreview name(String name) => call(name: name);

  @override
  PackBotPreview description(String description) =>
      call(description: description);

  @override
  PackBotPreview icon(String icon) => call(icon: icon);

  @override
  PackBotPreview mascot(String mascot) => call(mascot: mascot);

  @override
  PackBotPreview autonomy(PackBotPreviewAutonomyEnum autonomy) =>
      call(autonomy: autonomy);

  @override
  PackBotPreview persona(String persona) => call(persona: persona);

  @override
  PackBotPreview starters(List<String> starters) => call(starters: starters);

  @override
  PackBotPreview skills(List<String> skills) => call(skills: skills);

  @override
  PackBotPreview routines(List<String> routines) => call(routines: routines);

  @override
  PackBotPreview tools(List<String> tools) => call(tools: tools);

  @override
  PackBotPreview rules(List<PackBotPreviewRulesInner>? rules) =>
      call(rules: rules);

  @override
  PackBotPreview knowledge(List<PackBotPreviewKnowledgeInner>? knowledge) =>
      call(knowledge: knowledge);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackBotPreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackBotPreview(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackBotPreview call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? mascot = const $CopyWithPlaceholder(),
    Object? autonomy = const $CopyWithPlaceholder(),
    Object? persona = const $CopyWithPlaceholder(),
    Object? starters = const $CopyWithPlaceholder(),
    Object? skills = const $CopyWithPlaceholder(),
    Object? routines = const $CopyWithPlaceholder(),
    Object? tools = const $CopyWithPlaceholder(),
    Object? rules = const $CopyWithPlaceholder(),
    Object? knowledge = const $CopyWithPlaceholder(),
  }) {
    return PackBotPreview(
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
      icon: icon == const $CopyWithPlaceholder() || icon == null
          ? _value.icon
          // ignore: cast_nullable_to_non_nullable
          : icon as String,
      mascot: mascot == const $CopyWithPlaceholder() || mascot == null
          ? _value.mascot
          // ignore: cast_nullable_to_non_nullable
          : mascot as String,
      autonomy: autonomy == const $CopyWithPlaceholder() || autonomy == null
          ? _value.autonomy
          // ignore: cast_nullable_to_non_nullable
          : autonomy as PackBotPreviewAutonomyEnum,
      persona: persona == const $CopyWithPlaceholder() || persona == null
          ? _value.persona
          // ignore: cast_nullable_to_non_nullable
          : persona as String,
      starters: starters == const $CopyWithPlaceholder() || starters == null
          ? _value.starters
          // ignore: cast_nullable_to_non_nullable
          : starters as List<String>,
      skills: skills == const $CopyWithPlaceholder() || skills == null
          ? _value.skills
          // ignore: cast_nullable_to_non_nullable
          : skills as List<String>,
      routines: routines == const $CopyWithPlaceholder() || routines == null
          ? _value.routines
          // ignore: cast_nullable_to_non_nullable
          : routines as List<String>,
      tools: tools == const $CopyWithPlaceholder() || tools == null
          ? _value.tools
          // ignore: cast_nullable_to_non_nullable
          : tools as List<String>,
      rules: rules == const $CopyWithPlaceholder()
          ? _value.rules
          // ignore: cast_nullable_to_non_nullable
          : rules as List<PackBotPreviewRulesInner>?,
      knowledge: knowledge == const $CopyWithPlaceholder()
          ? _value.knowledge
          // ignore: cast_nullable_to_non_nullable
          : knowledge as List<PackBotPreviewKnowledgeInner>?,
    );
  }
}

extension $PackBotPreviewCopyWith on PackBotPreview {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackBotPreview.copyWith(...)` or `instanceOfPackBotPreview.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackBotPreviewCWProxy get copyWith => _$PackBotPreviewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackBotPreview _$PackBotPreviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PackBotPreview', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'name',
          'description',
          'icon',
          'mascot',
          'autonomy',
          'persona',
          'starters',
          'skills',
          'routines',
          'tools',
        ],
      );
      final val = PackBotPreview(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String),
        icon: $checkedConvert('icon', (v) => v as String),
        mascot: $checkedConvert('mascot', (v) => v as String),
        autonomy: $checkedConvert(
          'autonomy',
          (v) => $enumDecode(_$PackBotPreviewAutonomyEnumEnumMap, v),
        ),
        persona: $checkedConvert('persona', (v) => v as String),
        starters: $checkedConvert(
          'starters',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        skills: $checkedConvert(
          'skills',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        routines: $checkedConvert(
          'routines',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        tools: $checkedConvert(
          'tools',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        rules: $checkedConvert(
          'rules',
          (v) => (v as List<dynamic>?)
              ?.map(
                (e) => PackBotPreviewRulesInner.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
        knowledge: $checkedConvert(
          'knowledge',
          (v) => (v as List<dynamic>?)
              ?.map(
                (e) => PackBotPreviewKnowledgeInner.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PackBotPreviewToJson(PackBotPreview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'icon': instance.icon,
      'mascot': instance.mascot,
      'autonomy': _$PackBotPreviewAutonomyEnumEnumMap[instance.autonomy]!,
      'persona': instance.persona,
      'starters': instance.starters,
      'skills': instance.skills,
      'routines': instance.routines,
      'tools': instance.tools,
      'rules': ?instance.rules?.map((e) => e.toJson()).toList(),
      'knowledge': ?instance.knowledge?.map((e) => e.toJson()).toList(),
    };

const _$PackBotPreviewAutonomyEnumEnumMap = {
  PackBotPreviewAutonomyEnum.askAlways: 'ask_always',
  PackBotPreviewAutonomyEnum.askRisky: 'ask_risky',
};

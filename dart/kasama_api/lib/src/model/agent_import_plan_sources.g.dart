// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_import_plan_sources.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AgentImportPlanSourcesCWProxy {
  AgentImportPlanSources skills(List<String> skills);

  AgentImportPlanSources routines(List<String> routines);

  AgentImportPlanSources memories(List<String> memories);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AgentImportPlanSources(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AgentImportPlanSources(...).copyWith(id: 12, name: "My name")
  /// ```
  AgentImportPlanSources call({
    List<String> skills,
    List<String> routines,
    List<String> memories,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAgentImportPlanSources.copyWith(...)` or call `instanceOfAgentImportPlanSources.copyWith.fieldName(value)` for a single field.
class _$AgentImportPlanSourcesCWProxyImpl
    implements _$AgentImportPlanSourcesCWProxy {
  const _$AgentImportPlanSourcesCWProxyImpl(this._value);

  final AgentImportPlanSources _value;

  @override
  AgentImportPlanSources skills(List<String> skills) => call(skills: skills);

  @override
  AgentImportPlanSources routines(List<String> routines) =>
      call(routines: routines);

  @override
  AgentImportPlanSources memories(List<String> memories) =>
      call(memories: memories);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AgentImportPlanSources(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AgentImportPlanSources(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AgentImportPlanSources call({
    Object? skills = const $CopyWithPlaceholder(),
    Object? routines = const $CopyWithPlaceholder(),
    Object? memories = const $CopyWithPlaceholder(),
  }) {
    return AgentImportPlanSources(
      skills: skills == const $CopyWithPlaceholder() || skills == null
          ? _value.skills
          // ignore: cast_nullable_to_non_nullable
          : skills as List<String>,
      routines: routines == const $CopyWithPlaceholder() || routines == null
          ? _value.routines
          // ignore: cast_nullable_to_non_nullable
          : routines as List<String>,
      memories: memories == const $CopyWithPlaceholder() || memories == null
          ? _value.memories
          // ignore: cast_nullable_to_non_nullable
          : memories as List<String>,
    );
  }
}

extension $AgentImportPlanSourcesCopyWith on AgentImportPlanSources {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAgentImportPlanSources.copyWith(...)` or `instanceOfAgentImportPlanSources.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AgentImportPlanSourcesCWProxy get copyWith =>
      _$AgentImportPlanSourcesCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentImportPlanSources _$AgentImportPlanSourcesFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentImportPlanSources', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['skills', 'routines', 'memories']);
  final val = AgentImportPlanSources(
    skills: $checkedConvert(
      'skills',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
    routines: $checkedConvert(
      'routines',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
    memories: $checkedConvert(
      'memories',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$AgentImportPlanSourcesToJson(
  AgentImportPlanSources instance,
) => <String, dynamic>{
  'skills': instance.skills,
  'routines': instance.routines,
  'memories': instance.memories,
};

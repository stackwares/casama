// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_import_plan.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AgentImportPlanCWProxy {
  AgentImportPlan id(String id);

  AgentImportPlan kind(AgentImportPlanKindEnum kind);

  AgentImportPlan template(BotTemplateFile template);

  AgentImportPlan sources(AgentImportPlanSources sources);

  AgentImportPlan leftovers(List<AgentImportPlanLeftoversInner> leftovers);

  AgentImportPlan skipped(List<AgentImportPlanSkippedInner> skipped);

  AgentImportPlan notes(List<String> notes);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AgentImportPlan(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AgentImportPlan(...).copyWith(id: 12, name: "My name")
  /// ```
  AgentImportPlan call({
    String id,
    AgentImportPlanKindEnum kind,
    BotTemplateFile template,
    AgentImportPlanSources sources,
    List<AgentImportPlanLeftoversInner> leftovers,
    List<AgentImportPlanSkippedInner> skipped,
    List<String> notes,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAgentImportPlan.copyWith(...)` or call `instanceOfAgentImportPlan.copyWith.fieldName(value)` for a single field.
class _$AgentImportPlanCWProxyImpl implements _$AgentImportPlanCWProxy {
  const _$AgentImportPlanCWProxyImpl(this._value);

  final AgentImportPlan _value;

  @override
  AgentImportPlan id(String id) => call(id: id);

  @override
  AgentImportPlan kind(AgentImportPlanKindEnum kind) => call(kind: kind);

  @override
  AgentImportPlan template(BotTemplateFile template) =>
      call(template: template);

  @override
  AgentImportPlan sources(AgentImportPlanSources sources) =>
      call(sources: sources);

  @override
  AgentImportPlan leftovers(List<AgentImportPlanLeftoversInner> leftovers) =>
      call(leftovers: leftovers);

  @override
  AgentImportPlan skipped(List<AgentImportPlanSkippedInner> skipped) =>
      call(skipped: skipped);

  @override
  AgentImportPlan notes(List<String> notes) => call(notes: notes);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AgentImportPlan(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AgentImportPlan(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AgentImportPlan call({
    Object? id = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? template = const $CopyWithPlaceholder(),
    Object? sources = const $CopyWithPlaceholder(),
    Object? leftovers = const $CopyWithPlaceholder(),
    Object? skipped = const $CopyWithPlaceholder(),
    Object? notes = const $CopyWithPlaceholder(),
  }) {
    return AgentImportPlan(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as AgentImportPlanKindEnum,
      template: template == const $CopyWithPlaceholder() || template == null
          ? _value.template
          // ignore: cast_nullable_to_non_nullable
          : template as BotTemplateFile,
      sources: sources == const $CopyWithPlaceholder() || sources == null
          ? _value.sources
          // ignore: cast_nullable_to_non_nullable
          : sources as AgentImportPlanSources,
      leftovers: leftovers == const $CopyWithPlaceholder() || leftovers == null
          ? _value.leftovers
          // ignore: cast_nullable_to_non_nullable
          : leftovers as List<AgentImportPlanLeftoversInner>,
      skipped: skipped == const $CopyWithPlaceholder() || skipped == null
          ? _value.skipped
          // ignore: cast_nullable_to_non_nullable
          : skipped as List<AgentImportPlanSkippedInner>,
      notes: notes == const $CopyWithPlaceholder() || notes == null
          ? _value.notes
          // ignore: cast_nullable_to_non_nullable
          : notes as List<String>,
    );
  }
}

extension $AgentImportPlanCopyWith on AgentImportPlan {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAgentImportPlan.copyWith(...)` or `instanceOfAgentImportPlan.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AgentImportPlanCWProxy get copyWith => _$AgentImportPlanCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentImportPlan _$AgentImportPlanFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AgentImportPlan', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'kind',
          'template',
          'sources',
          'leftovers',
          'skipped',
          'notes',
        ],
      );
      final val = AgentImportPlan(
        id: $checkedConvert('id', (v) => v as String),
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$AgentImportPlanKindEnumEnumMap, v),
        ),
        template: $checkedConvert(
          'template',
          (v) => BotTemplateFile.fromJson(v as Map<String, dynamic>),
        ),
        sources: $checkedConvert(
          'sources',
          (v) => AgentImportPlanSources.fromJson(v as Map<String, dynamic>),
        ),
        leftovers: $checkedConvert(
          'leftovers',
          (v) => (v as List<dynamic>)
              .map(
                (e) => AgentImportPlanLeftoversInner.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
        skipped: $checkedConvert(
          'skipped',
          (v) => (v as List<dynamic>)
              .map(
                (e) => AgentImportPlanSkippedInner.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
        notes: $checkedConvert(
          'notes',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AgentImportPlanToJson(AgentImportPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$AgentImportPlanKindEnumEnumMap[instance.kind]!,
      'template': instance.template.toJson(),
      'sources': instance.sources.toJson(),
      'leftovers': instance.leftovers.map((e) => e.toJson()).toList(),
      'skipped': instance.skipped.map((e) => e.toJson()).toList(),
      'notes': instance.notes,
    };

const _$AgentImportPlanKindEnumEnumMap = {
  AgentImportPlanKindEnum.openclaw: 'openclaw',
  AgentImportPlanKindEnum.hermes: 'hermes',
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_import_plan_skipped_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AgentImportPlanSkippedInnerCWProxy {
  AgentImportPlanSkippedInner path(String path);

  AgentImportPlanSkippedInner reason(String reason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AgentImportPlanSkippedInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AgentImportPlanSkippedInner(...).copyWith(id: 12, name: "My name")
  /// ```
  AgentImportPlanSkippedInner call({String path, String reason});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAgentImportPlanSkippedInner.copyWith(...)` or call `instanceOfAgentImportPlanSkippedInner.copyWith.fieldName(value)` for a single field.
class _$AgentImportPlanSkippedInnerCWProxyImpl
    implements _$AgentImportPlanSkippedInnerCWProxy {
  const _$AgentImportPlanSkippedInnerCWProxyImpl(this._value);

  final AgentImportPlanSkippedInner _value;

  @override
  AgentImportPlanSkippedInner path(String path) => call(path: path);

  @override
  AgentImportPlanSkippedInner reason(String reason) => call(reason: reason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AgentImportPlanSkippedInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AgentImportPlanSkippedInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AgentImportPlanSkippedInner call({
    Object? path = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
  }) {
    return AgentImportPlanSkippedInner(
      path: path == const $CopyWithPlaceholder() || path == null
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
    );
  }
}

extension $AgentImportPlanSkippedInnerCopyWith on AgentImportPlanSkippedInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAgentImportPlanSkippedInner.copyWith(...)` or `instanceOfAgentImportPlanSkippedInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AgentImportPlanSkippedInnerCWProxy get copyWith =>
      _$AgentImportPlanSkippedInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentImportPlanSkippedInner _$AgentImportPlanSkippedInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentImportPlanSkippedInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['path', 'reason']);
  final val = AgentImportPlanSkippedInner(
    path: $checkedConvert('path', (v) => v as String),
    reason: $checkedConvert('reason', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$AgentImportPlanSkippedInnerToJson(
  AgentImportPlanSkippedInner instance,
) => <String, dynamic>{'path': instance.path, 'reason': instance.reason};

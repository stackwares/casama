// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_import_plan_leftovers_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AgentImportPlanLeftoversInnerCWProxy {
  AgentImportPlanLeftoversInner path(String path);

  AgentImportPlanLeftoversInner size(int size);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AgentImportPlanLeftoversInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AgentImportPlanLeftoversInner(...).copyWith(id: 12, name: "My name")
  /// ```
  AgentImportPlanLeftoversInner call({String path, int size});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAgentImportPlanLeftoversInner.copyWith(...)` or call `instanceOfAgentImportPlanLeftoversInner.copyWith.fieldName(value)` for a single field.
class _$AgentImportPlanLeftoversInnerCWProxyImpl
    implements _$AgentImportPlanLeftoversInnerCWProxy {
  const _$AgentImportPlanLeftoversInnerCWProxyImpl(this._value);

  final AgentImportPlanLeftoversInner _value;

  @override
  AgentImportPlanLeftoversInner path(String path) => call(path: path);

  @override
  AgentImportPlanLeftoversInner size(int size) => call(size: size);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AgentImportPlanLeftoversInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AgentImportPlanLeftoversInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AgentImportPlanLeftoversInner call({
    Object? path = const $CopyWithPlaceholder(),
    Object? size = const $CopyWithPlaceholder(),
  }) {
    return AgentImportPlanLeftoversInner(
      path: path == const $CopyWithPlaceholder() || path == null
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      size: size == const $CopyWithPlaceholder() || size == null
          ? _value.size
          // ignore: cast_nullable_to_non_nullable
          : size as int,
    );
  }
}

extension $AgentImportPlanLeftoversInnerCopyWith
    on AgentImportPlanLeftoversInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAgentImportPlanLeftoversInner.copyWith(...)` or `instanceOfAgentImportPlanLeftoversInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AgentImportPlanLeftoversInnerCWProxy get copyWith =>
      _$AgentImportPlanLeftoversInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentImportPlanLeftoversInner _$AgentImportPlanLeftoversInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentImportPlanLeftoversInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['path', 'size']);
  final val = AgentImportPlanLeftoversInner(
    path: $checkedConvert('path', (v) => v as String),
    size: $checkedConvert('size', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$AgentImportPlanLeftoversInnerToJson(
  AgentImportPlanLeftoversInner instance,
) => <String, dynamic>{'path': instance.path, 'size': instance.size};

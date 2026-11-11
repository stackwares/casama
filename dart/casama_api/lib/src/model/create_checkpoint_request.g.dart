// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_checkpoint_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateCheckpointRequestCWProxy {
  CreateCheckpointRequest label(String label);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateCheckpointRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateCheckpointRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateCheckpointRequest call({String label});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateCheckpointRequest.copyWith(...)` or call `instanceOfCreateCheckpointRequest.copyWith.fieldName(value)` for a single field.
class _$CreateCheckpointRequestCWProxyImpl
    implements _$CreateCheckpointRequestCWProxy {
  const _$CreateCheckpointRequestCWProxyImpl(this._value);

  final CreateCheckpointRequest _value;

  @override
  CreateCheckpointRequest label(String label) => call(label: label);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateCheckpointRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateCheckpointRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateCheckpointRequest call({Object? label = const $CopyWithPlaceholder()}) {
    return CreateCheckpointRequest(
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
    );
  }
}

extension $CreateCheckpointRequestCopyWith on CreateCheckpointRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateCheckpointRequest.copyWith(...)` or `instanceOfCreateCheckpointRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateCheckpointRequestCWProxy get copyWith =>
      _$CreateCheckpointRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateCheckpointRequest _$CreateCheckpointRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateCheckpointRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['label']);
  final val = CreateCheckpointRequest(
    label: $checkedConvert('label', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$CreateCheckpointRequestToJson(
  CreateCheckpointRequest instance,
) => <String, dynamic>{'label': instance.label};

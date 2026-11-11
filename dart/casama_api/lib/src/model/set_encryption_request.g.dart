// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_encryption_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetEncryptionRequestCWProxy {
  SetEncryptionRequest enabled(bool enabled);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetEncryptionRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetEncryptionRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetEncryptionRequest call({bool enabled});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetEncryptionRequest.copyWith(...)` or call `instanceOfSetEncryptionRequest.copyWith.fieldName(value)` for a single field.
class _$SetEncryptionRequestCWProxyImpl
    implements _$SetEncryptionRequestCWProxy {
  const _$SetEncryptionRequestCWProxyImpl(this._value);

  final SetEncryptionRequest _value;

  @override
  SetEncryptionRequest enabled(bool enabled) => call(enabled: enabled);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetEncryptionRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetEncryptionRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetEncryptionRequest call({Object? enabled = const $CopyWithPlaceholder()}) {
    return SetEncryptionRequest(
      enabled: enabled == const $CopyWithPlaceholder() || enabled == null
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
    );
  }
}

extension $SetEncryptionRequestCopyWith on SetEncryptionRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetEncryptionRequest.copyWith(...)` or `instanceOfSetEncryptionRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetEncryptionRequestCWProxy get copyWith =>
      _$SetEncryptionRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetEncryptionRequest _$SetEncryptionRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SetEncryptionRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['enabled']);
  final val = SetEncryptionRequest(
    enabled: $checkedConvert('enabled', (v) => v as bool),
  );
  return val;
});

Map<String, dynamic> _$SetEncryptionRequestToJson(
  SetEncryptionRequest instance,
) => <String, dynamic>{'enabled': instance.enabled};

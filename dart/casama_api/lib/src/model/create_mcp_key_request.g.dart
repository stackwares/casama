// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_mcp_key_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateMcpKeyRequestCWProxy {
  CreateMcpKeyRequest name(String name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateMcpKeyRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateMcpKeyRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateMcpKeyRequest call({String name});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateMcpKeyRequest.copyWith(...)` or call `instanceOfCreateMcpKeyRequest.copyWith.fieldName(value)` for a single field.
class _$CreateMcpKeyRequestCWProxyImpl implements _$CreateMcpKeyRequestCWProxy {
  const _$CreateMcpKeyRequestCWProxyImpl(this._value);

  final CreateMcpKeyRequest _value;

  @override
  CreateMcpKeyRequest name(String name) => call(name: name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateMcpKeyRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateMcpKeyRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateMcpKeyRequest call({Object? name = const $CopyWithPlaceholder()}) {
    return CreateMcpKeyRequest(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $CreateMcpKeyRequestCopyWith on CreateMcpKeyRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateMcpKeyRequest.copyWith(...)` or `instanceOfCreateMcpKeyRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateMcpKeyRequestCWProxy get copyWith =>
      _$CreateMcpKeyRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateMcpKeyRequest _$CreateMcpKeyRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateMcpKeyRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name']);
      final val = CreateMcpKeyRequest(
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$CreateMcpKeyRequestToJson(
  CreateMcpKeyRequest instance,
) => <String, dynamic>{'name': instance.name};

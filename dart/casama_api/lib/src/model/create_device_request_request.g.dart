// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_device_request_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateDeviceRequestRequestCWProxy {
  CreateDeviceRequestRequest kind(CreateDeviceRequestRequestKindEnum kind);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateDeviceRequestRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateDeviceRequestRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateDeviceRequestRequest call({CreateDeviceRequestRequestKindEnum kind});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateDeviceRequestRequest.copyWith(...)` or call `instanceOfCreateDeviceRequestRequest.copyWith.fieldName(value)` for a single field.
class _$CreateDeviceRequestRequestCWProxyImpl
    implements _$CreateDeviceRequestRequestCWProxy {
  const _$CreateDeviceRequestRequestCWProxyImpl(this._value);

  final CreateDeviceRequestRequest _value;

  @override
  CreateDeviceRequestRequest kind(CreateDeviceRequestRequestKindEnum kind) =>
      call(kind: kind);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateDeviceRequestRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateDeviceRequestRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateDeviceRequestRequest call({
    Object? kind = const $CopyWithPlaceholder(),
  }) {
    return CreateDeviceRequestRequest(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as CreateDeviceRequestRequestKindEnum,
    );
  }
}

extension $CreateDeviceRequestRequestCopyWith on CreateDeviceRequestRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateDeviceRequestRequest.copyWith(...)` or `instanceOfCreateDeviceRequestRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateDeviceRequestRequestCWProxy get copyWith =>
      _$CreateDeviceRequestRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateDeviceRequestRequest _$CreateDeviceRequestRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateDeviceRequestRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['kind']);
  final val = CreateDeviceRequestRequest(
    kind: $checkedConvert(
      'kind',
      (v) => $enumDecode(_$CreateDeviceRequestRequestKindEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$CreateDeviceRequestRequestToJson(
  CreateDeviceRequestRequest instance,
) => <String, dynamic>{
  'kind': _$CreateDeviceRequestRequestKindEnumEnumMap[instance.kind]!,
};

const _$CreateDeviceRequestRequestKindEnumEnumMap = {
  CreateDeviceRequestRequestKindEnum.browserTab: 'browser_tab',
};

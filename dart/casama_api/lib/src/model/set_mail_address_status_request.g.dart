// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_mail_address_status_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetMailAddressStatusRequestCWProxy {
  SetMailAddressStatusRequest status(
    SetMailAddressStatusRequestStatusEnum status,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetMailAddressStatusRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetMailAddressStatusRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetMailAddressStatusRequest call({
    SetMailAddressStatusRequestStatusEnum status,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetMailAddressStatusRequest.copyWith(...)` or call `instanceOfSetMailAddressStatusRequest.copyWith.fieldName(value)` for a single field.
class _$SetMailAddressStatusRequestCWProxyImpl
    implements _$SetMailAddressStatusRequestCWProxy {
  const _$SetMailAddressStatusRequestCWProxyImpl(this._value);

  final SetMailAddressStatusRequest _value;

  @override
  SetMailAddressStatusRequest status(
    SetMailAddressStatusRequestStatusEnum status,
  ) => call(status: status);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetMailAddressStatusRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetMailAddressStatusRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetMailAddressStatusRequest call({
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return SetMailAddressStatusRequest(
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as SetMailAddressStatusRequestStatusEnum,
    );
  }
}

extension $SetMailAddressStatusRequestCopyWith on SetMailAddressStatusRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetMailAddressStatusRequest.copyWith(...)` or `instanceOfSetMailAddressStatusRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetMailAddressStatusRequestCWProxy get copyWith =>
      _$SetMailAddressStatusRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetMailAddressStatusRequest _$SetMailAddressStatusRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SetMailAddressStatusRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['status']);
  final val = SetMailAddressStatusRequest(
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$SetMailAddressStatusRequestStatusEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$SetMailAddressStatusRequestToJson(
  SetMailAddressStatusRequest instance,
) => <String, dynamic>{
  'status': _$SetMailAddressStatusRequestStatusEnumEnumMap[instance.status]!,
};

const _$SetMailAddressStatusRequestStatusEnumEnumMap = {
  SetMailAddressStatusRequestStatusEnum.active: 'active',
  SetMailAddressStatusRequestStatusEnum.paused: 'paused',
};

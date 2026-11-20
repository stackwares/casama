// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_mail_address_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateMailAddressRequestCWProxy {
  UpdateMailAddressRequest status(UpdateMailAddressRequestStatusEnum? status);

  UpdateMailAddressRequest notifyNewSenders(bool? notifyNewSenders);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateMailAddressRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateMailAddressRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateMailAddressRequest call({
    UpdateMailAddressRequestStatusEnum? status,
    bool? notifyNewSenders,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateMailAddressRequest.copyWith(...)` or call `instanceOfUpdateMailAddressRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateMailAddressRequestCWProxyImpl
    implements _$UpdateMailAddressRequestCWProxy {
  const _$UpdateMailAddressRequestCWProxyImpl(this._value);

  final UpdateMailAddressRequest _value;

  @override
  UpdateMailAddressRequest status(UpdateMailAddressRequestStatusEnum? status) =>
      call(status: status);

  @override
  UpdateMailAddressRequest notifyNewSenders(bool? notifyNewSenders) =>
      call(notifyNewSenders: notifyNewSenders);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateMailAddressRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateMailAddressRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateMailAddressRequest call({
    Object? status = const $CopyWithPlaceholder(),
    Object? notifyNewSenders = const $CopyWithPlaceholder(),
  }) {
    return UpdateMailAddressRequest(
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as UpdateMailAddressRequestStatusEnum?,
      notifyNewSenders: notifyNewSenders == const $CopyWithPlaceholder()
          ? _value.notifyNewSenders
          // ignore: cast_nullable_to_non_nullable
          : notifyNewSenders as bool?,
    );
  }
}

extension $UpdateMailAddressRequestCopyWith on UpdateMailAddressRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateMailAddressRequest.copyWith(...)` or `instanceOfUpdateMailAddressRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateMailAddressRequestCWProxy get copyWith =>
      _$UpdateMailAddressRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateMailAddressRequest _$UpdateMailAddressRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UpdateMailAddressRequest', json, ($checkedConvert) {
  final val = UpdateMailAddressRequest(
    status: $checkedConvert(
      'status',
      (v) =>
          $enumDecodeNullable(_$UpdateMailAddressRequestStatusEnumEnumMap, v),
    ),
    notifyNewSenders: $checkedConvert('notify_new_senders', (v) => v as bool?),
  );
  return val;
}, fieldKeyMap: const {'notifyNewSenders': 'notify_new_senders'});

Map<String, dynamic> _$UpdateMailAddressRequestToJson(
  UpdateMailAddressRequest instance,
) => <String, dynamic>{
  'status': ?_$UpdateMailAddressRequestStatusEnumEnumMap[instance.status],
  'notify_new_senders': ?instance.notifyNewSenders,
};

const _$UpdateMailAddressRequestStatusEnumEnumMap = {
  UpdateMailAddressRequestStatusEnum.active: 'active',
  UpdateMailAddressRequestStatusEnum.paused: 'paused',
};

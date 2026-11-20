// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_device_check_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminDeviceCheckRequestCWProxy {
  AdminDeviceCheckRequest challengeId(String challengeId);

  AdminDeviceCheckRequest signature(String signature);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminDeviceCheckRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminDeviceCheckRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminDeviceCheckRequest call({String challengeId, String signature});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminDeviceCheckRequest.copyWith(...)` or call `instanceOfAdminDeviceCheckRequest.copyWith.fieldName(value)` for a single field.
class _$AdminDeviceCheckRequestCWProxyImpl
    implements _$AdminDeviceCheckRequestCWProxy {
  const _$AdminDeviceCheckRequestCWProxyImpl(this._value);

  final AdminDeviceCheckRequest _value;

  @override
  AdminDeviceCheckRequest challengeId(String challengeId) =>
      call(challengeId: challengeId);

  @override
  AdminDeviceCheckRequest signature(String signature) =>
      call(signature: signature);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminDeviceCheckRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminDeviceCheckRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminDeviceCheckRequest call({
    Object? challengeId = const $CopyWithPlaceholder(),
    Object? signature = const $CopyWithPlaceholder(),
  }) {
    return AdminDeviceCheckRequest(
      challengeId:
          challengeId == const $CopyWithPlaceholder() || challengeId == null
          ? _value.challengeId
          // ignore: cast_nullable_to_non_nullable
          : challengeId as String,
      signature: signature == const $CopyWithPlaceholder() || signature == null
          ? _value.signature
          // ignore: cast_nullable_to_non_nullable
          : signature as String,
    );
  }
}

extension $AdminDeviceCheckRequestCopyWith on AdminDeviceCheckRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminDeviceCheckRequest.copyWith(...)` or `instanceOfAdminDeviceCheckRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminDeviceCheckRequestCWProxy get copyWith =>
      _$AdminDeviceCheckRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminDeviceCheckRequest _$AdminDeviceCheckRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminDeviceCheckRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['challenge_id', 'signature']);
  final val = AdminDeviceCheckRequest(
    challengeId: $checkedConvert('challenge_id', (v) => v as String),
    signature: $checkedConvert('signature', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'challengeId': 'challenge_id'});

Map<String, dynamic> _$AdminDeviceCheckRequestToJson(
  AdminDeviceCheckRequest instance,
) => <String, dynamic>{
  'challenge_id': instance.challengeId,
  'signature': instance.signature,
};

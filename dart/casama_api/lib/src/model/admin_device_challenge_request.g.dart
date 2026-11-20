// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_device_challenge_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminDeviceChallengeRequestCWProxy {
  AdminDeviceChallengeRequest keyId(String keyId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminDeviceChallengeRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminDeviceChallengeRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminDeviceChallengeRequest call({String keyId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminDeviceChallengeRequest.copyWith(...)` or call `instanceOfAdminDeviceChallengeRequest.copyWith.fieldName(value)` for a single field.
class _$AdminDeviceChallengeRequestCWProxyImpl
    implements _$AdminDeviceChallengeRequestCWProxy {
  const _$AdminDeviceChallengeRequestCWProxyImpl(this._value);

  final AdminDeviceChallengeRequest _value;

  @override
  AdminDeviceChallengeRequest keyId(String keyId) => call(keyId: keyId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminDeviceChallengeRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminDeviceChallengeRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminDeviceChallengeRequest call({
    Object? keyId = const $CopyWithPlaceholder(),
  }) {
    return AdminDeviceChallengeRequest(
      keyId: keyId == const $CopyWithPlaceholder() || keyId == null
          ? _value.keyId
          // ignore: cast_nullable_to_non_nullable
          : keyId as String,
    );
  }
}

extension $AdminDeviceChallengeRequestCopyWith on AdminDeviceChallengeRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminDeviceChallengeRequest.copyWith(...)` or `instanceOfAdminDeviceChallengeRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminDeviceChallengeRequestCWProxy get copyWith =>
      _$AdminDeviceChallengeRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminDeviceChallengeRequest _$AdminDeviceChallengeRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminDeviceChallengeRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['key_id']);
  final val = AdminDeviceChallengeRequest(
    keyId: $checkedConvert('key_id', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'keyId': 'key_id'});

Map<String, dynamic> _$AdminDeviceChallengeRequestToJson(
  AdminDeviceChallengeRequest instance,
) => <String, dynamic>{'key_id': instance.keyId};

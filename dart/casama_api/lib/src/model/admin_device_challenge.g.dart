// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_device_challenge.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminDeviceChallengeCWProxy {
  AdminDeviceChallenge challengeId(String challengeId);

  AdminDeviceChallenge challenge(String challenge);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminDeviceChallenge(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminDeviceChallenge(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminDeviceChallenge call({String challengeId, String challenge});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminDeviceChallenge.copyWith(...)` or call `instanceOfAdminDeviceChallenge.copyWith.fieldName(value)` for a single field.
class _$AdminDeviceChallengeCWProxyImpl
    implements _$AdminDeviceChallengeCWProxy {
  const _$AdminDeviceChallengeCWProxyImpl(this._value);

  final AdminDeviceChallenge _value;

  @override
  AdminDeviceChallenge challengeId(String challengeId) =>
      call(challengeId: challengeId);

  @override
  AdminDeviceChallenge challenge(String challenge) =>
      call(challenge: challenge);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminDeviceChallenge(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminDeviceChallenge(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminDeviceChallenge call({
    Object? challengeId = const $CopyWithPlaceholder(),
    Object? challenge = const $CopyWithPlaceholder(),
  }) {
    return AdminDeviceChallenge(
      challengeId:
          challengeId == const $CopyWithPlaceholder() || challengeId == null
          ? _value.challengeId
          // ignore: cast_nullable_to_non_nullable
          : challengeId as String,
      challenge: challenge == const $CopyWithPlaceholder() || challenge == null
          ? _value.challenge
          // ignore: cast_nullable_to_non_nullable
          : challenge as String,
    );
  }
}

extension $AdminDeviceChallengeCopyWith on AdminDeviceChallenge {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminDeviceChallenge.copyWith(...)` or `instanceOfAdminDeviceChallenge.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminDeviceChallengeCWProxy get copyWith =>
      _$AdminDeviceChallengeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminDeviceChallenge _$AdminDeviceChallengeFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminDeviceChallenge', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['challenge_id', 'challenge']);
  final val = AdminDeviceChallenge(
    challengeId: $checkedConvert('challenge_id', (v) => v as String),
    challenge: $checkedConvert('challenge', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'challengeId': 'challenge_id'});

Map<String, dynamic> _$AdminDeviceChallengeToJson(
  AdminDeviceChallenge instance,
) => <String, dynamic>{
  'challenge_id': instance.challengeId,
  'challenge': instance.challenge,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waitlist_proof.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WaitlistProofCWProxy {
  WaitlistProof challenge(String challenge);

  WaitlistProof nonce(String nonce);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WaitlistProof(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WaitlistProof(...).copyWith(id: 12, name: "My name")
  /// ```
  WaitlistProof call({String challenge, String nonce});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWaitlistProof.copyWith(...)` or call `instanceOfWaitlistProof.copyWith.fieldName(value)` for a single field.
class _$WaitlistProofCWProxyImpl implements _$WaitlistProofCWProxy {
  const _$WaitlistProofCWProxyImpl(this._value);

  final WaitlistProof _value;

  @override
  WaitlistProof challenge(String challenge) => call(challenge: challenge);

  @override
  WaitlistProof nonce(String nonce) => call(nonce: nonce);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WaitlistProof(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WaitlistProof(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WaitlistProof call({
    Object? challenge = const $CopyWithPlaceholder(),
    Object? nonce = const $CopyWithPlaceholder(),
  }) {
    return WaitlistProof(
      challenge: challenge == const $CopyWithPlaceholder() || challenge == null
          ? _value.challenge
          // ignore: cast_nullable_to_non_nullable
          : challenge as String,
      nonce: nonce == const $CopyWithPlaceholder() || nonce == null
          ? _value.nonce
          // ignore: cast_nullable_to_non_nullable
          : nonce as String,
    );
  }
}

extension $WaitlistProofCopyWith on WaitlistProof {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWaitlistProof.copyWith(...)` or `instanceOfWaitlistProof.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WaitlistProofCWProxy get copyWith => _$WaitlistProofCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WaitlistProof _$WaitlistProofFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WaitlistProof', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['challenge', 'nonce']);
      final val = WaitlistProof(
        challenge: $checkedConvert('challenge', (v) => v as String),
        nonce: $checkedConvert('nonce', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$WaitlistProofToJson(WaitlistProof instance) =>
    <String, dynamic>{'challenge': instance.challenge, 'nonce': instance.nonce};

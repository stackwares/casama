// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_challenge.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SignupChallengeCWProxy {
  SignupChallenge challenge(String challenge);

  SignupChallenge difficulty(int difficulty);

  SignupChallenge expiresAt(String expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SignupChallenge(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SignupChallenge(...).copyWith(id: 12, name: "My name")
  /// ```
  SignupChallenge call({String challenge, int difficulty, String expiresAt});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSignupChallenge.copyWith(...)` or call `instanceOfSignupChallenge.copyWith.fieldName(value)` for a single field.
class _$SignupChallengeCWProxyImpl implements _$SignupChallengeCWProxy {
  const _$SignupChallengeCWProxyImpl(this._value);

  final SignupChallenge _value;

  @override
  SignupChallenge challenge(String challenge) => call(challenge: challenge);

  @override
  SignupChallenge difficulty(int difficulty) => call(difficulty: difficulty);

  @override
  SignupChallenge expiresAt(String expiresAt) => call(expiresAt: expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SignupChallenge(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SignupChallenge(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SignupChallenge call({
    Object? challenge = const $CopyWithPlaceholder(),
    Object? difficulty = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
  }) {
    return SignupChallenge(
      challenge: challenge == const $CopyWithPlaceholder() || challenge == null
          ? _value.challenge
          // ignore: cast_nullable_to_non_nullable
          : challenge as String,
      difficulty:
          difficulty == const $CopyWithPlaceholder() || difficulty == null
          ? _value.difficulty
          // ignore: cast_nullable_to_non_nullable
          : difficulty as int,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as String,
    );
  }
}

extension $SignupChallengeCopyWith on SignupChallenge {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSignupChallenge.copyWith(...)` or `instanceOfSignupChallenge.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SignupChallengeCWProxy get copyWith => _$SignupChallengeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignupChallenge _$SignupChallengeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SignupChallenge', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['challenge', 'difficulty', 'expires_at'],
      );
      final val = SignupChallenge(
        challenge: $checkedConvert('challenge', (v) => v as String),
        difficulty: $checkedConvert('difficulty', (v) => (v as num).toInt()),
        expiresAt: $checkedConvert('expires_at', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'expiresAt': 'expires_at'});

Map<String, dynamic> _$SignupChallengeToJson(SignupChallenge instance) =>
    <String, dynamic>{
      'challenge': instance.challenge,
      'difficulty': instance.difficulty,
      'expires_at': instance.expiresAt,
    };

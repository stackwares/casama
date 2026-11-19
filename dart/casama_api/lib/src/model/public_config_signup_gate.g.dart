// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_config_signup_gate.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicConfigSignupGateCWProxy {
  PublicConfigSignupGate mode(String mode);

  PublicConfigSignupGate waitlistUrl(String waitlistUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublicConfigSignupGate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublicConfigSignupGate(...).copyWith(id: 12, name: "My name")
  /// ```
  PublicConfigSignupGate call({String mode, String waitlistUrl});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPublicConfigSignupGate.copyWith(...)` or call `instanceOfPublicConfigSignupGate.copyWith.fieldName(value)` for a single field.
class _$PublicConfigSignupGateCWProxyImpl
    implements _$PublicConfigSignupGateCWProxy {
  const _$PublicConfigSignupGateCWProxyImpl(this._value);

  final PublicConfigSignupGate _value;

  @override
  PublicConfigSignupGate mode(String mode) => call(mode: mode);

  @override
  PublicConfigSignupGate waitlistUrl(String waitlistUrl) =>
      call(waitlistUrl: waitlistUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublicConfigSignupGate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublicConfigSignupGate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PublicConfigSignupGate call({
    Object? mode = const $CopyWithPlaceholder(),
    Object? waitlistUrl = const $CopyWithPlaceholder(),
  }) {
    return PublicConfigSignupGate(
      mode: mode == const $CopyWithPlaceholder() || mode == null
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as String,
      waitlistUrl:
          waitlistUrl == const $CopyWithPlaceholder() || waitlistUrl == null
          ? _value.waitlistUrl
          // ignore: cast_nullable_to_non_nullable
          : waitlistUrl as String,
    );
  }
}

extension $PublicConfigSignupGateCopyWith on PublicConfigSignupGate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPublicConfigSignupGate.copyWith(...)` or `instanceOfPublicConfigSignupGate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicConfigSignupGateCWProxy get copyWith =>
      _$PublicConfigSignupGateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicConfigSignupGate _$PublicConfigSignupGateFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PublicConfigSignupGate', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['mode', 'waitlist_url']);
  final val = PublicConfigSignupGate(
    mode: $checkedConvert('mode', (v) => v as String),
    waitlistUrl: $checkedConvert('waitlist_url', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'waitlistUrl': 'waitlist_url'});

Map<String, dynamic> _$PublicConfigSignupGateToJson(
  PublicConfigSignupGate instance,
) => <String, dynamic>{
  'mode': instance.mode,
  'waitlist_url': instance.waitlistUrl,
};

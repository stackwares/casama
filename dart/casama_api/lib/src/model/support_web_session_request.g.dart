// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_web_session_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SupportWebSessionRequestCWProxy {
  SupportWebSessionRequest turnstileToken(String turnstileToken);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportWebSessionRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportWebSessionRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SupportWebSessionRequest call({String turnstileToken});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSupportWebSessionRequest.copyWith(...)` or call `instanceOfSupportWebSessionRequest.copyWith.fieldName(value)` for a single field.
class _$SupportWebSessionRequestCWProxyImpl
    implements _$SupportWebSessionRequestCWProxy {
  const _$SupportWebSessionRequestCWProxyImpl(this._value);

  final SupportWebSessionRequest _value;

  @override
  SupportWebSessionRequest turnstileToken(String turnstileToken) =>
      call(turnstileToken: turnstileToken);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportWebSessionRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportWebSessionRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SupportWebSessionRequest call({
    Object? turnstileToken = const $CopyWithPlaceholder(),
  }) {
    return SupportWebSessionRequest(
      turnstileToken:
          turnstileToken == const $CopyWithPlaceholder() ||
              turnstileToken == null
          ? _value.turnstileToken
          // ignore: cast_nullable_to_non_nullable
          : turnstileToken as String,
    );
  }
}

extension $SupportWebSessionRequestCopyWith on SupportWebSessionRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSupportWebSessionRequest.copyWith(...)` or `instanceOfSupportWebSessionRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SupportWebSessionRequestCWProxy get copyWith =>
      _$SupportWebSessionRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportWebSessionRequest _$SupportWebSessionRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SupportWebSessionRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['turnstile_token']);
  final val = SupportWebSessionRequest(
    turnstileToken: $checkedConvert('turnstile_token', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'turnstileToken': 'turnstile_token'});

Map<String, dynamic> _$SupportWebSessionRequestToJson(
  SupportWebSessionRequest instance,
) => <String, dynamic>{'turnstile_token': instance.turnstileToken};

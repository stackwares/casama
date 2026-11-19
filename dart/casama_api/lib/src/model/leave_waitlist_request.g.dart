// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_waitlist_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LeaveWaitlistRequestCWProxy {
  LeaveWaitlistRequest token(String token);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LeaveWaitlistRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LeaveWaitlistRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  LeaveWaitlistRequest call({String token});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLeaveWaitlistRequest.copyWith(...)` or call `instanceOfLeaveWaitlistRequest.copyWith.fieldName(value)` for a single field.
class _$LeaveWaitlistRequestCWProxyImpl
    implements _$LeaveWaitlistRequestCWProxy {
  const _$LeaveWaitlistRequestCWProxyImpl(this._value);

  final LeaveWaitlistRequest _value;

  @override
  LeaveWaitlistRequest token(String token) => call(token: token);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LeaveWaitlistRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LeaveWaitlistRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LeaveWaitlistRequest call({Object? token = const $CopyWithPlaceholder()}) {
    return LeaveWaitlistRequest(
      token: token == const $CopyWithPlaceholder() || token == null
          ? _value.token
          // ignore: cast_nullable_to_non_nullable
          : token as String,
    );
  }
}

extension $LeaveWaitlistRequestCopyWith on LeaveWaitlistRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLeaveWaitlistRequest.copyWith(...)` or `instanceOfLeaveWaitlistRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LeaveWaitlistRequestCWProxy get copyWith =>
      _$LeaveWaitlistRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaveWaitlistRequest _$LeaveWaitlistRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('LeaveWaitlistRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['token']);
  final val = LeaveWaitlistRequest(
    token: $checkedConvert('token', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$LeaveWaitlistRequestToJson(
  LeaveWaitlistRequest instance,
) => <String, dynamic>{'token': instance.token};

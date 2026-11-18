// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suspend_link_server_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SuspendLinkServerRequestCWProxy {
  SuspendLinkServerRequest reason(String reason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SuspendLinkServerRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SuspendLinkServerRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SuspendLinkServerRequest call({String reason});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSuspendLinkServerRequest.copyWith(...)` or call `instanceOfSuspendLinkServerRequest.copyWith.fieldName(value)` for a single field.
class _$SuspendLinkServerRequestCWProxyImpl
    implements _$SuspendLinkServerRequestCWProxy {
  const _$SuspendLinkServerRequestCWProxyImpl(this._value);

  final SuspendLinkServerRequest _value;

  @override
  SuspendLinkServerRequest reason(String reason) => call(reason: reason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SuspendLinkServerRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SuspendLinkServerRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SuspendLinkServerRequest call({
    Object? reason = const $CopyWithPlaceholder(),
  }) {
    return SuspendLinkServerRequest(
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
    );
  }
}

extension $SuspendLinkServerRequestCopyWith on SuspendLinkServerRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSuspendLinkServerRequest.copyWith(...)` or `instanceOfSuspendLinkServerRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SuspendLinkServerRequestCWProxy get copyWith =>
      _$SuspendLinkServerRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SuspendLinkServerRequest _$SuspendLinkServerRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SuspendLinkServerRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['reason']);
  final val = SuspendLinkServerRequest(
    reason: $checkedConvert('reason', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$SuspendLinkServerRequestToJson(
  SuspendLinkServerRequest instance,
) => <String, dynamic>{'reason': instance.reason};

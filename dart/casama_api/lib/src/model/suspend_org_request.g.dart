// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suspend_org_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SuspendOrgRequestCWProxy {
  SuspendOrgRequest reason(String reason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SuspendOrgRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SuspendOrgRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SuspendOrgRequest call({String reason});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSuspendOrgRequest.copyWith(...)` or call `instanceOfSuspendOrgRequest.copyWith.fieldName(value)` for a single field.
class _$SuspendOrgRequestCWProxyImpl implements _$SuspendOrgRequestCWProxy {
  const _$SuspendOrgRequestCWProxyImpl(this._value);

  final SuspendOrgRequest _value;

  @override
  SuspendOrgRequest reason(String reason) => call(reason: reason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SuspendOrgRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SuspendOrgRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SuspendOrgRequest call({Object? reason = const $CopyWithPlaceholder()}) {
    return SuspendOrgRequest(
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
    );
  }
}

extension $SuspendOrgRequestCopyWith on SuspendOrgRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSuspendOrgRequest.copyWith(...)` or `instanceOfSuspendOrgRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SuspendOrgRequestCWProxy get copyWith =>
      _$SuspendOrgRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SuspendOrgRequest _$SuspendOrgRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SuspendOrgRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reason']);
      final val = SuspendOrgRequest(
        reason: $checkedConvert('reason', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SuspendOrgRequestToJson(SuspendOrgRequest instance) =>
    <String, dynamic>{'reason': instance.reason};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_org_limits_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetOrgLimitsRequestCWProxy {
  SetOrgLimitsRequest limits(Map<String, num> limits);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetOrgLimitsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetOrgLimitsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetOrgLimitsRequest call({Map<String, num> limits});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetOrgLimitsRequest.copyWith(...)` or call `instanceOfSetOrgLimitsRequest.copyWith.fieldName(value)` for a single field.
class _$SetOrgLimitsRequestCWProxyImpl implements _$SetOrgLimitsRequestCWProxy {
  const _$SetOrgLimitsRequestCWProxyImpl(this._value);

  final SetOrgLimitsRequest _value;

  @override
  SetOrgLimitsRequest limits(Map<String, num> limits) => call(limits: limits);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetOrgLimitsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetOrgLimitsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetOrgLimitsRequest call({Object? limits = const $CopyWithPlaceholder()}) {
    return SetOrgLimitsRequest(
      limits: limits == const $CopyWithPlaceholder() || limits == null
          ? _value.limits
          // ignore: cast_nullable_to_non_nullable
          : limits as Map<String, num>,
    );
  }
}

extension $SetOrgLimitsRequestCopyWith on SetOrgLimitsRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetOrgLimitsRequest.copyWith(...)` or `instanceOfSetOrgLimitsRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetOrgLimitsRequestCWProxy get copyWith =>
      _$SetOrgLimitsRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetOrgLimitsRequest _$SetOrgLimitsRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SetOrgLimitsRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['limits']);
      final val = SetOrgLimitsRequest(
        limits: $checkedConvert(
          'limits',
          (v) => Map<String, num>.from(v as Map),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SetOrgLimitsRequestToJson(
  SetOrgLimitsRequest instance,
) => <String, dynamic>{'limits': instance.limits};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_call_limits_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SaveCallLimitsRequestCWProxy {
  SaveCallLimitsRequest limits(Map<String, int> limits);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveCallLimitsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveCallLimitsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SaveCallLimitsRequest call({Map<String, int> limits});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSaveCallLimitsRequest.copyWith(...)` or call `instanceOfSaveCallLimitsRequest.copyWith.fieldName(value)` for a single field.
class _$SaveCallLimitsRequestCWProxyImpl
    implements _$SaveCallLimitsRequestCWProxy {
  const _$SaveCallLimitsRequestCWProxyImpl(this._value);

  final SaveCallLimitsRequest _value;

  @override
  SaveCallLimitsRequest limits(Map<String, int> limits) => call(limits: limits);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveCallLimitsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveCallLimitsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SaveCallLimitsRequest call({Object? limits = const $CopyWithPlaceholder()}) {
    return SaveCallLimitsRequest(
      limits: limits == const $CopyWithPlaceholder() || limits == null
          ? _value.limits
          // ignore: cast_nullable_to_non_nullable
          : limits as Map<String, int>,
    );
  }
}

extension $SaveCallLimitsRequestCopyWith on SaveCallLimitsRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSaveCallLimitsRequest.copyWith(...)` or `instanceOfSaveCallLimitsRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SaveCallLimitsRequestCWProxy get copyWith =>
      _$SaveCallLimitsRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveCallLimitsRequest _$SaveCallLimitsRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SaveCallLimitsRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['limits']);
  final val = SaveCallLimitsRequest(
    limits: $checkedConvert('limits', (v) => Map<String, int>.from(v as Map)),
  );
  return val;
});

Map<String, dynamic> _$SaveCallLimitsRequestToJson(
  SaveCallLimitsRequest instance,
) => <String, dynamic>{'limits': instance.limits};

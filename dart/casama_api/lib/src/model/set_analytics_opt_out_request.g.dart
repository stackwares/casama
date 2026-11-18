// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_analytics_opt_out_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetAnalyticsOptOutRequestCWProxy {
  SetAnalyticsOptOutRequest optOut(bool optOut);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetAnalyticsOptOutRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetAnalyticsOptOutRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetAnalyticsOptOutRequest call({bool optOut});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetAnalyticsOptOutRequest.copyWith(...)` or call `instanceOfSetAnalyticsOptOutRequest.copyWith.fieldName(value)` for a single field.
class _$SetAnalyticsOptOutRequestCWProxyImpl
    implements _$SetAnalyticsOptOutRequestCWProxy {
  const _$SetAnalyticsOptOutRequestCWProxyImpl(this._value);

  final SetAnalyticsOptOutRequest _value;

  @override
  SetAnalyticsOptOutRequest optOut(bool optOut) => call(optOut: optOut);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetAnalyticsOptOutRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetAnalyticsOptOutRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetAnalyticsOptOutRequest call({
    Object? optOut = const $CopyWithPlaceholder(),
  }) {
    return SetAnalyticsOptOutRequest(
      optOut: optOut == const $CopyWithPlaceholder() || optOut == null
          ? _value.optOut
          // ignore: cast_nullable_to_non_nullable
          : optOut as bool,
    );
  }
}

extension $SetAnalyticsOptOutRequestCopyWith on SetAnalyticsOptOutRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetAnalyticsOptOutRequest.copyWith(...)` or `instanceOfSetAnalyticsOptOutRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetAnalyticsOptOutRequestCWProxy get copyWith =>
      _$SetAnalyticsOptOutRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetAnalyticsOptOutRequest _$SetAnalyticsOptOutRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SetAnalyticsOptOutRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['opt_out']);
  final val = SetAnalyticsOptOutRequest(
    optOut: $checkedConvert('opt_out', (v) => v as bool),
  );
  return val;
}, fieldKeyMap: const {'optOut': 'opt_out'});

Map<String, dynamic> _$SetAnalyticsOptOutRequestToJson(
  SetAnalyticsOptOutRequest instance,
) => <String, dynamic>{'opt_out': instance.optOut};

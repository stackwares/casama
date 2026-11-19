// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_call_limits.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminCallLimitsCWProxy {
  AdminCallLimits limits(Map<String, int> limits);

  AdminCallLimits builtIn(Map<String, int> builtIn);

  AdminCallLimits inUse(Map<String, int> inUse);

  AdminCallLimits ranges(Map<String, List<int>> ranges);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminCallLimits(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminCallLimits(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminCallLimits call({
    Map<String, int> limits,
    Map<String, int> builtIn,
    Map<String, int> inUse,
    Map<String, List<int>> ranges,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminCallLimits.copyWith(...)` or call `instanceOfAdminCallLimits.copyWith.fieldName(value)` for a single field.
class _$AdminCallLimitsCWProxyImpl implements _$AdminCallLimitsCWProxy {
  const _$AdminCallLimitsCWProxyImpl(this._value);

  final AdminCallLimits _value;

  @override
  AdminCallLimits limits(Map<String, int> limits) => call(limits: limits);

  @override
  AdminCallLimits builtIn(Map<String, int> builtIn) => call(builtIn: builtIn);

  @override
  AdminCallLimits inUse(Map<String, int> inUse) => call(inUse: inUse);

  @override
  AdminCallLimits ranges(Map<String, List<int>> ranges) => call(ranges: ranges);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminCallLimits(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminCallLimits(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminCallLimits call({
    Object? limits = const $CopyWithPlaceholder(),
    Object? builtIn = const $CopyWithPlaceholder(),
    Object? inUse = const $CopyWithPlaceholder(),
    Object? ranges = const $CopyWithPlaceholder(),
  }) {
    return AdminCallLimits(
      limits: limits == const $CopyWithPlaceholder() || limits == null
          ? _value.limits
          // ignore: cast_nullable_to_non_nullable
          : limits as Map<String, int>,
      builtIn: builtIn == const $CopyWithPlaceholder() || builtIn == null
          ? _value.builtIn
          // ignore: cast_nullable_to_non_nullable
          : builtIn as Map<String, int>,
      inUse: inUse == const $CopyWithPlaceholder() || inUse == null
          ? _value.inUse
          // ignore: cast_nullable_to_non_nullable
          : inUse as Map<String, int>,
      ranges: ranges == const $CopyWithPlaceholder() || ranges == null
          ? _value.ranges
          // ignore: cast_nullable_to_non_nullable
          : ranges as Map<String, List<int>>,
    );
  }
}

extension $AdminCallLimitsCopyWith on AdminCallLimits {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminCallLimits.copyWith(...)` or `instanceOfAdminCallLimits.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminCallLimitsCWProxy get copyWith => _$AdminCallLimitsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminCallLimits _$AdminCallLimitsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminCallLimits', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['limits', 'built_in', 'in_use', 'ranges'],
  );
  final val = AdminCallLimits(
    limits: $checkedConvert('limits', (v) => Map<String, int>.from(v as Map)),
    builtIn: $checkedConvert(
      'built_in',
      (v) => Map<String, int>.from(v as Map),
    ),
    inUse: $checkedConvert('in_use', (v) => Map<String, int>.from(v as Map)),
    ranges: $checkedConvert(
      'ranges',
      (v) => (v as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          k,
          (e as List<dynamic>).map((e) => (e as num).toInt()).toList(),
        ),
      ),
    ),
  );
  return val;
}, fieldKeyMap: const {'builtIn': 'built_in', 'inUse': 'in_use'});

Map<String, dynamic> _$AdminCallLimitsToJson(AdminCallLimits instance) =>
    <String, dynamic>{
      'limits': instance.limits,
      'built_in': instance.builtIn,
      'in_use': instance.inUse,
      'ranges': instance.ranges,
    };

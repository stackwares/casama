// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_usage.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerUsageCWProxy {
  ComputerUsage monthStart(String monthStart);

  ComputerUsage seconds(int seconds);

  ComputerUsage costUsd(num costUsd);

  ComputerUsage days(List<ComputerUsageDay> days);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerUsage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerUsage(...).copyWith(id: 12, name: "My name")
  /// ```
  ComputerUsage call({
    String monthStart,
    int seconds,
    num costUsd,
    List<ComputerUsageDay> days,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComputerUsage.copyWith(...)` or call `instanceOfComputerUsage.copyWith.fieldName(value)` for a single field.
class _$ComputerUsageCWProxyImpl implements _$ComputerUsageCWProxy {
  const _$ComputerUsageCWProxyImpl(this._value);

  final ComputerUsage _value;

  @override
  ComputerUsage monthStart(String monthStart) => call(monthStart: monthStart);

  @override
  ComputerUsage seconds(int seconds) => call(seconds: seconds);

  @override
  ComputerUsage costUsd(num costUsd) => call(costUsd: costUsd);

  @override
  ComputerUsage days(List<ComputerUsageDay> days) => call(days: days);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerUsage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerUsage(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComputerUsage call({
    Object? monthStart = const $CopyWithPlaceholder(),
    Object? seconds = const $CopyWithPlaceholder(),
    Object? costUsd = const $CopyWithPlaceholder(),
    Object? days = const $CopyWithPlaceholder(),
  }) {
    return ComputerUsage(
      monthStart:
          monthStart == const $CopyWithPlaceholder() || monthStart == null
          ? _value.monthStart
          // ignore: cast_nullable_to_non_nullable
          : monthStart as String,
      seconds: seconds == const $CopyWithPlaceholder() || seconds == null
          ? _value.seconds
          // ignore: cast_nullable_to_non_nullable
          : seconds as int,
      costUsd: costUsd == const $CopyWithPlaceholder() || costUsd == null
          ? _value.costUsd
          // ignore: cast_nullable_to_non_nullable
          : costUsd as num,
      days: days == const $CopyWithPlaceholder() || days == null
          ? _value.days
          // ignore: cast_nullable_to_non_nullable
          : days as List<ComputerUsageDay>,
    );
  }
}

extension $ComputerUsageCopyWith on ComputerUsage {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComputerUsage.copyWith(...)` or `instanceOfComputerUsage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComputerUsageCWProxy get copyWith => _$ComputerUsageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComputerUsage _$ComputerUsageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ComputerUsage', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['month_start', 'seconds', 'cost_usd', 'days'],
      );
      final val = ComputerUsage(
        monthStart: $checkedConvert('month_start', (v) => v as String),
        seconds: $checkedConvert('seconds', (v) => (v as num).toInt()),
        costUsd: $checkedConvert('cost_usd', (v) => v as num),
        days: $checkedConvert(
          'days',
          (v) => (v as List<dynamic>)
              .map((e) => ComputerUsageDay.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'monthStart': 'month_start', 'costUsd': 'cost_usd'});

Map<String, dynamic> _$ComputerUsageToJson(ComputerUsage instance) =>
    <String, dynamic>{
      'month_start': instance.monthStart,
      'seconds': instance.seconds,
      'cost_usd': instance.costUsd,
      'days': instance.days.map((e) => e.toJson()).toList(),
    };

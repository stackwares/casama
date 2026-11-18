// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_usage_day.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerUsageDayCWProxy {
  ComputerUsageDay date(String date);

  ComputerUsageDay seconds(int seconds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerUsageDay(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerUsageDay(...).copyWith(id: 12, name: "My name")
  /// ```
  ComputerUsageDay call({String date, int seconds});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComputerUsageDay.copyWith(...)` or call `instanceOfComputerUsageDay.copyWith.fieldName(value)` for a single field.
class _$ComputerUsageDayCWProxyImpl implements _$ComputerUsageDayCWProxy {
  const _$ComputerUsageDayCWProxyImpl(this._value);

  final ComputerUsageDay _value;

  @override
  ComputerUsageDay date(String date) => call(date: date);

  @override
  ComputerUsageDay seconds(int seconds) => call(seconds: seconds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerUsageDay(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerUsageDay(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComputerUsageDay call({
    Object? date = const $CopyWithPlaceholder(),
    Object? seconds = const $CopyWithPlaceholder(),
  }) {
    return ComputerUsageDay(
      date: date == const $CopyWithPlaceholder() || date == null
          ? _value.date
          // ignore: cast_nullable_to_non_nullable
          : date as String,
      seconds: seconds == const $CopyWithPlaceholder() || seconds == null
          ? _value.seconds
          // ignore: cast_nullable_to_non_nullable
          : seconds as int,
    );
  }
}

extension $ComputerUsageDayCopyWith on ComputerUsageDay {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComputerUsageDay.copyWith(...)` or `instanceOfComputerUsageDay.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComputerUsageDayCWProxy get copyWith => _$ComputerUsageDayCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComputerUsageDay _$ComputerUsageDayFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ComputerUsageDay', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['date', 'seconds']);
      final val = ComputerUsageDay(
        date: $checkedConvert('date', (v) => v as String),
        seconds: $checkedConvert('seconds', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$ComputerUsageDayToJson(ComputerUsageDay instance) =>
    <String, dynamic>{'date': instance.date, 'seconds': instance.seconds};

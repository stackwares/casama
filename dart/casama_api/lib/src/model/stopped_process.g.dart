// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stopped_process.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StoppedProcessCWProxy {
  StoppedProcess stopped(int stopped);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `StoppedProcess(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StoppedProcess(...).copyWith(id: 12, name: "My name")
  /// ```
  StoppedProcess call({int stopped});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfStoppedProcess.copyWith(...)` or call `instanceOfStoppedProcess.copyWith.fieldName(value)` for a single field.
class _$StoppedProcessCWProxyImpl implements _$StoppedProcessCWProxy {
  const _$StoppedProcessCWProxyImpl(this._value);

  final StoppedProcess _value;

  @override
  StoppedProcess stopped(int stopped) => call(stopped: stopped);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `StoppedProcess(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StoppedProcess(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  StoppedProcess call({Object? stopped = const $CopyWithPlaceholder()}) {
    return StoppedProcess(
      stopped: stopped == const $CopyWithPlaceholder() || stopped == null
          ? _value.stopped
          // ignore: cast_nullable_to_non_nullable
          : stopped as int,
    );
  }
}

extension $StoppedProcessCopyWith on StoppedProcess {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfStoppedProcess.copyWith(...)` or `instanceOfStoppedProcess.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StoppedProcessCWProxy get copyWith => _$StoppedProcessCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoppedProcess _$StoppedProcessFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StoppedProcess', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['stopped']);
      final val = StoppedProcess(
        stopped: $checkedConvert('stopped', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$StoppedProcessToJson(StoppedProcess instance) =>
    <String, dynamic>{'stopped': instance.stopped};

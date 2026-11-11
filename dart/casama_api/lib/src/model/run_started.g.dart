// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_started.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunStartedCWProxy {
  RunStarted runId(String runId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunStarted(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunStarted(...).copyWith(id: 12, name: "My name")
  /// ```
  RunStarted call({String runId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRunStarted.copyWith(...)` or call `instanceOfRunStarted.copyWith.fieldName(value)` for a single field.
class _$RunStartedCWProxyImpl implements _$RunStartedCWProxy {
  const _$RunStartedCWProxyImpl(this._value);

  final RunStarted _value;

  @override
  RunStarted runId(String runId) => call(runId: runId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunStarted(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunStarted(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RunStarted call({Object? runId = const $CopyWithPlaceholder()}) {
    return RunStarted(
      runId: runId == const $CopyWithPlaceholder() || runId == null
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String,
    );
  }
}

extension $RunStartedCopyWith on RunStarted {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRunStarted.copyWith(...)` or `instanceOfRunStarted.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RunStartedCWProxy get copyWith => _$RunStartedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunStarted _$RunStartedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RunStarted', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['run_id']);
      final val = RunStarted(
        runId: $checkedConvert('run_id', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id'});

Map<String, dynamic> _$RunStartedToJson(RunStarted instance) =>
    <String, dynamic>{'run_id': instance.runId};

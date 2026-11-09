// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_started.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunStartedCWProxy {
  RunStarted runId(String runId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RunStarted(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RunStarted(...).copyWith(id: 12, name: "My name")
  /// ````
  RunStarted call({String runId});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRunStarted.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRunStarted.copyWith.fieldName(...)`
class _$RunStartedCWProxyImpl implements _$RunStartedCWProxy {
  const _$RunStartedCWProxyImpl(this._value);

  final RunStarted _value;

  @override
  RunStarted runId(String runId) => this(runId: runId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RunStarted(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RunStarted(...).copyWith(id: 12, name: "My name")
  /// ````
  RunStarted call({Object? runId = const $CopyWithPlaceholder()}) {
    return RunStarted(
      runId: runId == const $CopyWithPlaceholder()
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String,
    );
  }
}

extension $RunStartedCopyWith on RunStarted {
  /// Returns a callable class that can be used as follows: `instanceOfRunStarted.copyWith(...)` or like so:`instanceOfRunStarted.copyWith.fieldName(...)`.
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

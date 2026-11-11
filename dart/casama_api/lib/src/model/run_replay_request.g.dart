// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_replay_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunReplayRequestCWProxy {
  RunReplayRequest params(Map<String, String>? params);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunReplayRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunReplayRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  RunReplayRequest call({Map<String, String>? params});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRunReplayRequest.copyWith(...)` or call `instanceOfRunReplayRequest.copyWith.fieldName(value)` for a single field.
class _$RunReplayRequestCWProxyImpl implements _$RunReplayRequestCWProxy {
  const _$RunReplayRequestCWProxyImpl(this._value);

  final RunReplayRequest _value;

  @override
  RunReplayRequest params(Map<String, String>? params) => call(params: params);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunReplayRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunReplayRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RunReplayRequest call({Object? params = const $CopyWithPlaceholder()}) {
    return RunReplayRequest(
      params: params == const $CopyWithPlaceholder()
          ? _value.params
          // ignore: cast_nullable_to_non_nullable
          : params as Map<String, String>?,
    );
  }
}

extension $RunReplayRequestCopyWith on RunReplayRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRunReplayRequest.copyWith(...)` or `instanceOfRunReplayRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RunReplayRequestCWProxy get copyWith => _$RunReplayRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunReplayRequest _$RunReplayRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RunReplayRequest', json, ($checkedConvert) {
      final val = RunReplayRequest(
        params: $checkedConvert(
          'params',
          (v) => (v as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ),
        ),
      );
      return val;
    });

Map<String, dynamic> _$RunReplayRequestToJson(RunReplayRequest instance) =>
    <String, dynamic>{'params': ?instance.params};

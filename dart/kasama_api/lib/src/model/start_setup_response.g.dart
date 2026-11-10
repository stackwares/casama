// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'start_setup_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StartSetupResponseCWProxy {
  StartSetupResponse conversationId(String conversationId);

  StartSetupResponse runId(String runId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `StartSetupResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StartSetupResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  StartSetupResponse call({String conversationId, String runId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfStartSetupResponse.copyWith(...)` or call `instanceOfStartSetupResponse.copyWith.fieldName(value)` for a single field.
class _$StartSetupResponseCWProxyImpl implements _$StartSetupResponseCWProxy {
  const _$StartSetupResponseCWProxyImpl(this._value);

  final StartSetupResponse _value;

  @override
  StartSetupResponse conversationId(String conversationId) =>
      call(conversationId: conversationId);

  @override
  StartSetupResponse runId(String runId) => call(runId: runId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `StartSetupResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StartSetupResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  StartSetupResponse call({
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
  }) {
    return StartSetupResponse(
      conversationId:
          conversationId == const $CopyWithPlaceholder() ||
              conversationId == null
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String,
      runId: runId == const $CopyWithPlaceholder() || runId == null
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String,
    );
  }
}

extension $StartSetupResponseCopyWith on StartSetupResponse {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfStartSetupResponse.copyWith(...)` or `instanceOfStartSetupResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StartSetupResponseCWProxy get copyWith =>
      _$StartSetupResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StartSetupResponse _$StartSetupResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('StartSetupResponse', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['conversation_id', 'run_id']);
  final val = StartSetupResponse(
    conversationId: $checkedConvert('conversation_id', (v) => v as String),
    runId: $checkedConvert('run_id', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'conversationId': 'conversation_id', 'runId': 'run_id'});

Map<String, dynamic> _$StartSetupResponseToJson(StartSetupResponse instance) =>
    <String, dynamic>{
      'conversation_id': instance.conversationId,
      'run_id': instance.runId,
    };

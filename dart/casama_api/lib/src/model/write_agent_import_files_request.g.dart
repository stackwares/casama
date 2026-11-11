// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'write_agent_import_files_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WriteAgentImportFilesRequestCWProxy {
  WriteAgentImportFilesRequest botId(String botId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WriteAgentImportFilesRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WriteAgentImportFilesRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  WriteAgentImportFilesRequest call({String botId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWriteAgentImportFilesRequest.copyWith(...)` or call `instanceOfWriteAgentImportFilesRequest.copyWith.fieldName(value)` for a single field.
class _$WriteAgentImportFilesRequestCWProxyImpl
    implements _$WriteAgentImportFilesRequestCWProxy {
  const _$WriteAgentImportFilesRequestCWProxyImpl(this._value);

  final WriteAgentImportFilesRequest _value;

  @override
  WriteAgentImportFilesRequest botId(String botId) => call(botId: botId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WriteAgentImportFilesRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WriteAgentImportFilesRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WriteAgentImportFilesRequest call({
    Object? botId = const $CopyWithPlaceholder(),
  }) {
    return WriteAgentImportFilesRequest(
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
    );
  }
}

extension $WriteAgentImportFilesRequestCopyWith
    on WriteAgentImportFilesRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWriteAgentImportFilesRequest.copyWith(...)` or `instanceOfWriteAgentImportFilesRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WriteAgentImportFilesRequestCWProxy get copyWith =>
      _$WriteAgentImportFilesRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WriteAgentImportFilesRequest _$WriteAgentImportFilesRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('WriteAgentImportFilesRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['bot_id']);
  final val = WriteAgentImportFilesRequest(
    botId: $checkedConvert('bot_id', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'botId': 'bot_id'});

Map<String, dynamic> _$WriteAgentImportFilesRequestToJson(
  WriteAgentImportFilesRequest instance,
) => <String, dynamic>{'bot_id': instance.botId};

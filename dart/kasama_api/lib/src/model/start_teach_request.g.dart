// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'start_teach_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StartTeachRequestCWProxy {
  StartTeachRequest computerId(String computerId);

  StartTeachRequest botId(String botId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `StartTeachRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StartTeachRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  StartTeachRequest call({String computerId, String botId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfStartTeachRequest.copyWith(...)` or call `instanceOfStartTeachRequest.copyWith.fieldName(value)` for a single field.
class _$StartTeachRequestCWProxyImpl implements _$StartTeachRequestCWProxy {
  const _$StartTeachRequestCWProxyImpl(this._value);

  final StartTeachRequest _value;

  @override
  StartTeachRequest computerId(String computerId) =>
      call(computerId: computerId);

  @override
  StartTeachRequest botId(String botId) => call(botId: botId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `StartTeachRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StartTeachRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  StartTeachRequest call({
    Object? computerId = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
  }) {
    return StartTeachRequest(
      computerId:
          computerId == const $CopyWithPlaceholder() || computerId == null
          ? _value.computerId
          // ignore: cast_nullable_to_non_nullable
          : computerId as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
    );
  }
}

extension $StartTeachRequestCopyWith on StartTeachRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfStartTeachRequest.copyWith(...)` or `instanceOfStartTeachRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StartTeachRequestCWProxy get copyWith =>
      _$StartTeachRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StartTeachRequest _$StartTeachRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StartTeachRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['computer_id', 'bot_id']);
      final val = StartTeachRequest(
        computerId: $checkedConvert('computer_id', (v) => v as String),
        botId: $checkedConvert('bot_id', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'computerId': 'computer_id', 'botId': 'bot_id'});

Map<String, dynamic> _$StartTeachRequestToJson(StartTeachRequest instance) =>
    <String, dynamic>{
      'computer_id': instance.computerId,
      'bot_id': instance.botId,
    };

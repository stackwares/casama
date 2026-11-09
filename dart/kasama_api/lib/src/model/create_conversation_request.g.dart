// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_conversation_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateConversationRequestCWProxy {
  CreateConversationRequest botId(String botId);

  CreateConversationRequest title(String? title);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateConversationRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateConversationRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateConversationRequest call({String botId, String? title});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateConversationRequest.copyWith(...)` or call `instanceOfCreateConversationRequest.copyWith.fieldName(value)` for a single field.
class _$CreateConversationRequestCWProxyImpl
    implements _$CreateConversationRequestCWProxy {
  const _$CreateConversationRequestCWProxyImpl(this._value);

  final CreateConversationRequest _value;

  @override
  CreateConversationRequest botId(String botId) => call(botId: botId);

  @override
  CreateConversationRequest title(String? title) => call(title: title);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateConversationRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateConversationRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateConversationRequest call({
    Object? botId = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
  }) {
    return CreateConversationRequest(
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String?,
    );
  }
}

extension $CreateConversationRequestCopyWith on CreateConversationRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateConversationRequest.copyWith(...)` or `instanceOfCreateConversationRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateConversationRequestCWProxy get copyWith =>
      _$CreateConversationRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateConversationRequest _$CreateConversationRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateConversationRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['bot_id']);
  final val = CreateConversationRequest(
    botId: $checkedConvert('bot_id', (v) => v as String),
    title: $checkedConvert('title', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'botId': 'bot_id'});

Map<String, dynamic> _$CreateConversationRequestToJson(
  CreateConversationRequest instance,
) => <String, dynamic>{'bot_id': instance.botId, 'title': ?instance.title};

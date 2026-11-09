// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_conversation_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateConversationRequestCWProxy {
  CreateConversationRequest botId(String botId);

  CreateConversationRequest title(String? title);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateConversationRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateConversationRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateConversationRequest call({String botId, String? title});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCreateConversationRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCreateConversationRequest.copyWith.fieldName(...)`
class _$CreateConversationRequestCWProxyImpl
    implements _$CreateConversationRequestCWProxy {
  const _$CreateConversationRequestCWProxyImpl(this._value);

  final CreateConversationRequest _value;

  @override
  CreateConversationRequest botId(String botId) => this(botId: botId);

  @override
  CreateConversationRequest title(String? title) => this(title: title);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateConversationRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateConversationRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateConversationRequest call({
    Object? botId = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
  }) {
    return CreateConversationRequest(
      botId: botId == const $CopyWithPlaceholder()
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
  /// Returns a callable class that can be used as follows: `instanceOfCreateConversationRequest.copyWith(...)` or like so:`instanceOfCreateConversationRequest.copyWith.fieldName(...)`.
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

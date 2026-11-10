// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'welcome_chat.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WelcomeChatCWProxy {
  WelcomeChat orgId(String orgId);

  WelcomeChat botId(String botId);

  WelcomeChat conversationId(String conversationId);

  WelcomeChat created(bool created);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WelcomeChat(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WelcomeChat(...).copyWith(id: 12, name: "My name")
  /// ```
  WelcomeChat call({
    String orgId,
    String botId,
    String conversationId,
    bool created,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWelcomeChat.copyWith(...)` or call `instanceOfWelcomeChat.copyWith.fieldName(value)` for a single field.
class _$WelcomeChatCWProxyImpl implements _$WelcomeChatCWProxy {
  const _$WelcomeChatCWProxyImpl(this._value);

  final WelcomeChat _value;

  @override
  WelcomeChat orgId(String orgId) => call(orgId: orgId);

  @override
  WelcomeChat botId(String botId) => call(botId: botId);

  @override
  WelcomeChat conversationId(String conversationId) =>
      call(conversationId: conversationId);

  @override
  WelcomeChat created(bool created) => call(created: created);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WelcomeChat(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WelcomeChat(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WelcomeChat call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? created = const $CopyWithPlaceholder(),
  }) {
    return WelcomeChat(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      conversationId:
          conversationId == const $CopyWithPlaceholder() ||
              conversationId == null
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String,
      created: created == const $CopyWithPlaceholder() || created == null
          ? _value.created
          // ignore: cast_nullable_to_non_nullable
          : created as bool,
    );
  }
}

extension $WelcomeChatCopyWith on WelcomeChat {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWelcomeChat.copyWith(...)` or `instanceOfWelcomeChat.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WelcomeChatCWProxy get copyWith => _$WelcomeChatCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WelcomeChat _$WelcomeChatFromJson(Map<String, dynamic> json) => $checkedCreate(
  'WelcomeChat',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['org_id', 'bot_id', 'conversation_id', 'created'],
    );
    final val = WelcomeChat(
      orgId: $checkedConvert('org_id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      conversationId: $checkedConvert('conversation_id', (v) => v as String),
      created: $checkedConvert('created', (v) => v as bool),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'botId': 'bot_id',
    'conversationId': 'conversation_id',
  },
);

Map<String, dynamic> _$WelcomeChatToJson(WelcomeChat instance) =>
    <String, dynamic>{
      'org_id': instance.orgId,
      'bot_id': instance.botId,
      'conversation_id': instance.conversationId,
      'created': instance.created,
    };

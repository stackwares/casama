// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accept_bot_link_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AcceptBotLinkRequestCWProxy {
  AcceptBotLinkRequest invite(String invite);

  AcceptBotLinkRequest botId(String botId);

  AcceptBotLinkRequest name(String name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AcceptBotLinkRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AcceptBotLinkRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  AcceptBotLinkRequest call({String invite, String botId, String name});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAcceptBotLinkRequest.copyWith(...)` or call `instanceOfAcceptBotLinkRequest.copyWith.fieldName(value)` for a single field.
class _$AcceptBotLinkRequestCWProxyImpl
    implements _$AcceptBotLinkRequestCWProxy {
  const _$AcceptBotLinkRequestCWProxyImpl(this._value);

  final AcceptBotLinkRequest _value;

  @override
  AcceptBotLinkRequest invite(String invite) => call(invite: invite);

  @override
  AcceptBotLinkRequest botId(String botId) => call(botId: botId);

  @override
  AcceptBotLinkRequest name(String name) => call(name: name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AcceptBotLinkRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AcceptBotLinkRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AcceptBotLinkRequest call({
    Object? invite = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return AcceptBotLinkRequest(
      invite: invite == const $CopyWithPlaceholder() || invite == null
          ? _value.invite
          // ignore: cast_nullable_to_non_nullable
          : invite as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $AcceptBotLinkRequestCopyWith on AcceptBotLinkRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAcceptBotLinkRequest.copyWith(...)` or `instanceOfAcceptBotLinkRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AcceptBotLinkRequestCWProxy get copyWith =>
      _$AcceptBotLinkRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcceptBotLinkRequest _$AcceptBotLinkRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AcceptBotLinkRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['invite', 'bot_id', 'name']);
  final val = AcceptBotLinkRequest(
    invite: $checkedConvert('invite', (v) => v as String),
    botId: $checkedConvert('bot_id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'botId': 'bot_id'});

Map<String, dynamic> _$AcceptBotLinkRequestToJson(
  AcceptBotLinkRequest instance,
) => <String, dynamic>{
  'invite': instance.invite,
  'bot_id': instance.botId,
  'name': instance.name,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_channel_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateChannelRequestCWProxy {
  CreateChannelRequest botId(String botId);

  CreateChannelRequest kind(ChannelKind kind);

  CreateChannelRequest name(String name);

  CreateChannelRequest config(Map<String, Object?>? config);

  CreateChannelRequest secrets(Map<String, String>? secrets);

  CreateChannelRequest allowedSenders(List<String> allowedSenders);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateChannelRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateChannelRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateChannelRequest call({
    String botId,
    ChannelKind kind,
    String name,
    Map<String, Object?>? config,
    Map<String, String>? secrets,
    List<String> allowedSenders,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateChannelRequest.copyWith(...)` or call `instanceOfCreateChannelRequest.copyWith.fieldName(value)` for a single field.
class _$CreateChannelRequestCWProxyImpl
    implements _$CreateChannelRequestCWProxy {
  const _$CreateChannelRequestCWProxyImpl(this._value);

  final CreateChannelRequest _value;

  @override
  CreateChannelRequest botId(String botId) => call(botId: botId);

  @override
  CreateChannelRequest kind(ChannelKind kind) => call(kind: kind);

  @override
  CreateChannelRequest name(String name) => call(name: name);

  @override
  CreateChannelRequest config(Map<String, Object?>? config) =>
      call(config: config);

  @override
  CreateChannelRequest secrets(Map<String, String>? secrets) =>
      call(secrets: secrets);

  @override
  CreateChannelRequest allowedSenders(List<String> allowedSenders) =>
      call(allowedSenders: allowedSenders);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateChannelRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateChannelRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateChannelRequest call({
    Object? botId = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? config = const $CopyWithPlaceholder(),
    Object? secrets = const $CopyWithPlaceholder(),
    Object? allowedSenders = const $CopyWithPlaceholder(),
  }) {
    return CreateChannelRequest(
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as ChannelKind,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      config: config == const $CopyWithPlaceholder()
          ? _value.config
          // ignore: cast_nullable_to_non_nullable
          : config as Map<String, Object?>?,
      secrets: secrets == const $CopyWithPlaceholder()
          ? _value.secrets
          // ignore: cast_nullable_to_non_nullable
          : secrets as Map<String, String>?,
      allowedSenders:
          allowedSenders == const $CopyWithPlaceholder() ||
              allowedSenders == null
          ? _value.allowedSenders
          // ignore: cast_nullable_to_non_nullable
          : allowedSenders as List<String>,
    );
  }
}

extension $CreateChannelRequestCopyWith on CreateChannelRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateChannelRequest.copyWith(...)` or `instanceOfCreateChannelRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateChannelRequestCWProxy get copyWith =>
      _$CreateChannelRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateChannelRequest _$CreateChannelRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateChannelRequest', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['bot_id', 'kind', 'name', 'allowed_senders'],
  );
  final val = CreateChannelRequest(
    botId: $checkedConvert('bot_id', (v) => v as String),
    kind: $checkedConvert('kind', (v) => $enumDecode(_$ChannelKindEnumMap, v)),
    name: $checkedConvert('name', (v) => v as String),
    config: $checkedConvert('config', (v) => v as Map<String, dynamic>?),
    secrets: $checkedConvert(
      'secrets',
      (v) =>
          (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as String)),
    ),
    allowedSenders: $checkedConvert(
      'allowed_senders',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'botId': 'bot_id', 'allowedSenders': 'allowed_senders'});

Map<String, dynamic> _$CreateChannelRequestToJson(
  CreateChannelRequest instance,
) => <String, dynamic>{
  'bot_id': instance.botId,
  'kind': _$ChannelKindEnumMap[instance.kind]!,
  'name': instance.name,
  'config': ?instance.config,
  'secrets': ?instance.secrets,
  'allowed_senders': instance.allowedSenders,
};

const _$ChannelKindEnumMap = {
  ChannelKind.telegram: 'telegram',
  ChannelKind.email: 'email',
  ChannelKind.sms: 'sms',
  ChannelKind.slack: 'slack',
  ChannelKind.whatsapp: 'whatsapp',
  ChannelKind.messenger: 'messenger',
  ChannelKind.feishu: 'feishu',
  ChannelKind.imessage: 'imessage',
  ChannelKind.teams: 'teams',
  ChannelKind.discord: 'discord',
  ChannelKind.linear: 'linear',
  ChannelKind.jira: 'jira',
};

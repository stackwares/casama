// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ChannelCWProxy {
  Channel id(String id);

  Channel botId(String botId);

  Channel kind(ChannelKind kind);

  Channel name(String name);

  Channel config(Map<String, Object?> config);

  Channel allowedSenders(List<String> allowedSenders);

  Channel enabled(bool enabled);

  Channel webhookUrl(String? webhookUrl);

  Channel verifyToken(String? verifyToken);

  Channel lastInboundAt(DateTime? lastInboundAt);

  Channel lastError(String? lastError);

  Channel createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Channel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Channel(...).copyWith(id: 12, name: "My name")
  /// ```
  Channel call({
    String id,
    String botId,
    ChannelKind kind,
    String name,
    Map<String, Object?> config,
    List<String> allowedSenders,
    bool enabled,
    String? webhookUrl,
    String? verifyToken,
    DateTime? lastInboundAt,
    String? lastError,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfChannel.copyWith(...)` or call `instanceOfChannel.copyWith.fieldName(value)` for a single field.
class _$ChannelCWProxyImpl implements _$ChannelCWProxy {
  const _$ChannelCWProxyImpl(this._value);

  final Channel _value;

  @override
  Channel id(String id) => call(id: id);

  @override
  Channel botId(String botId) => call(botId: botId);

  @override
  Channel kind(ChannelKind kind) => call(kind: kind);

  @override
  Channel name(String name) => call(name: name);

  @override
  Channel config(Map<String, Object?> config) => call(config: config);

  @override
  Channel allowedSenders(List<String> allowedSenders) =>
      call(allowedSenders: allowedSenders);

  @override
  Channel enabled(bool enabled) => call(enabled: enabled);

  @override
  Channel webhookUrl(String? webhookUrl) => call(webhookUrl: webhookUrl);

  @override
  Channel verifyToken(String? verifyToken) => call(verifyToken: verifyToken);

  @override
  Channel lastInboundAt(DateTime? lastInboundAt) =>
      call(lastInboundAt: lastInboundAt);

  @override
  Channel lastError(String? lastError) => call(lastError: lastError);

  @override
  Channel createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Channel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Channel(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Channel call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? config = const $CopyWithPlaceholder(),
    Object? allowedSenders = const $CopyWithPlaceholder(),
    Object? enabled = const $CopyWithPlaceholder(),
    Object? webhookUrl = const $CopyWithPlaceholder(),
    Object? verifyToken = const $CopyWithPlaceholder(),
    Object? lastInboundAt = const $CopyWithPlaceholder(),
    Object? lastError = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Channel(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
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
      config: config == const $CopyWithPlaceholder() || config == null
          ? _value.config
          // ignore: cast_nullable_to_non_nullable
          : config as Map<String, Object?>,
      allowedSenders:
          allowedSenders == const $CopyWithPlaceholder() ||
              allowedSenders == null
          ? _value.allowedSenders
          // ignore: cast_nullable_to_non_nullable
          : allowedSenders as List<String>,
      enabled: enabled == const $CopyWithPlaceholder() || enabled == null
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
      webhookUrl: webhookUrl == const $CopyWithPlaceholder()
          ? _value.webhookUrl
          // ignore: cast_nullable_to_non_nullable
          : webhookUrl as String?,
      verifyToken: verifyToken == const $CopyWithPlaceholder()
          ? _value.verifyToken
          // ignore: cast_nullable_to_non_nullable
          : verifyToken as String?,
      lastInboundAt: lastInboundAt == const $CopyWithPlaceholder()
          ? _value.lastInboundAt
          // ignore: cast_nullable_to_non_nullable
          : lastInboundAt as DateTime?,
      lastError: lastError == const $CopyWithPlaceholder()
          ? _value.lastError
          // ignore: cast_nullable_to_non_nullable
          : lastError as String?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $ChannelCopyWith on Channel {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfChannel.copyWith(...)` or `instanceOfChannel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ChannelCWProxy get copyWith => _$ChannelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Channel _$ChannelFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Channel',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'bot_id',
        'kind',
        'name',
        'config',
        'allowed_senders',
        'enabled',
        'webhook_url',
        'verify_token',
        'last_inbound_at',
        'last_error',
        'created_at',
      ],
    );
    final val = Channel(
      id: $checkedConvert('id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      kind: $checkedConvert(
        'kind',
        (v) => $enumDecode(_$ChannelKindEnumMap, v),
      ),
      name: $checkedConvert('name', (v) => v as String),
      config: $checkedConvert('config', (v) => v as Map<String, dynamic>),
      allowedSenders: $checkedConvert(
        'allowed_senders',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      enabled: $checkedConvert('enabled', (v) => v as bool),
      webhookUrl: $checkedConvert('webhook_url', (v) => v as String?),
      verifyToken: $checkedConvert('verify_token', (v) => v as String?),
      lastInboundAt: $checkedConvert(
        'last_inbound_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      lastError: $checkedConvert('last_error', (v) => v as String?),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'allowedSenders': 'allowed_senders',
    'webhookUrl': 'webhook_url',
    'verifyToken': 'verify_token',
    'lastInboundAt': 'last_inbound_at',
    'lastError': 'last_error',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$ChannelToJson(Channel instance) => <String, dynamic>{
  'id': instance.id,
  'bot_id': instance.botId,
  'kind': _$ChannelKindEnumMap[instance.kind]!,
  'name': instance.name,
  'config': instance.config,
  'allowed_senders': instance.allowedSenders,
  'enabled': instance.enabled,
  'webhook_url': instance.webhookUrl,
  'verify_token': instance.verifyToken,
  'last_inbound_at': instance.lastInboundAt?.toIso8601String(),
  'last_error': instance.lastError,
  'created_at': instance.createdAt.toIso8601String(),
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
};

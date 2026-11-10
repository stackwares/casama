// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_secret_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotSecretRequestCWProxy {
  BotSecretRequest id(String id);

  BotSecretRequest orgId(String orgId);

  BotSecretRequest botId(String botId);

  BotSecretRequest runId(String runId);

  BotSecretRequest conversationId(String? conversationId);

  BotSecretRequest name(String name);

  BotSecretRequest service(String service);

  BotSecretRequest allowedHosts(List<String> allowedHosts);

  BotSecretRequest reason(String reason);

  BotSecretRequest kind(SecretKind kind);

  BotSecretRequest status(BotSecretRequestStatusEnum status);

  BotSecretRequest expiresAt(DateTime expiresAt);

  BotSecretRequest createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotSecretRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotSecretRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  BotSecretRequest call({
    String id,
    String orgId,
    String botId,
    String runId,
    String? conversationId,
    String name,
    String service,
    List<String> allowedHosts,
    String reason,
    SecretKind kind,
    BotSecretRequestStatusEnum status,
    DateTime expiresAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotSecretRequest.copyWith(...)` or call `instanceOfBotSecretRequest.copyWith.fieldName(value)` for a single field.
class _$BotSecretRequestCWProxyImpl implements _$BotSecretRequestCWProxy {
  const _$BotSecretRequestCWProxyImpl(this._value);

  final BotSecretRequest _value;

  @override
  BotSecretRequest id(String id) => call(id: id);

  @override
  BotSecretRequest orgId(String orgId) => call(orgId: orgId);

  @override
  BotSecretRequest botId(String botId) => call(botId: botId);

  @override
  BotSecretRequest runId(String runId) => call(runId: runId);

  @override
  BotSecretRequest conversationId(String? conversationId) =>
      call(conversationId: conversationId);

  @override
  BotSecretRequest name(String name) => call(name: name);

  @override
  BotSecretRequest service(String service) => call(service: service);

  @override
  BotSecretRequest allowedHosts(List<String> allowedHosts) =>
      call(allowedHosts: allowedHosts);

  @override
  BotSecretRequest reason(String reason) => call(reason: reason);

  @override
  BotSecretRequest kind(SecretKind kind) => call(kind: kind);

  @override
  BotSecretRequest status(BotSecretRequestStatusEnum status) =>
      call(status: status);

  @override
  BotSecretRequest expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  @override
  BotSecretRequest createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotSecretRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotSecretRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotSecretRequest call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? service = const $CopyWithPlaceholder(),
    Object? allowedHosts = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return BotSecretRequest(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      runId: runId == const $CopyWithPlaceholder() || runId == null
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String,
      conversationId: conversationId == const $CopyWithPlaceholder()
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String?,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      service: service == const $CopyWithPlaceholder() || service == null
          ? _value.service
          // ignore: cast_nullable_to_non_nullable
          : service as String,
      allowedHosts:
          allowedHosts == const $CopyWithPlaceholder() || allowedHosts == null
          ? _value.allowedHosts
          // ignore: cast_nullable_to_non_nullable
          : allowedHosts as List<String>,
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as SecretKind,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as BotSecretRequestStatusEnum,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $BotSecretRequestCopyWith on BotSecretRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotSecretRequest.copyWith(...)` or `instanceOfBotSecretRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotSecretRequestCWProxy get copyWith => _$BotSecretRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotSecretRequest _$BotSecretRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'BotSecretRequest',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'org_id',
        'bot_id',
        'run_id',
        'conversation_id',
        'name',
        'service',
        'allowed_hosts',
        'reason',
        'kind',
        'status',
        'expires_at',
        'created_at',
      ],
    );
    final val = BotSecretRequest(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      runId: $checkedConvert('run_id', (v) => v as String),
      conversationId: $checkedConvert('conversation_id', (v) => v as String?),
      name: $checkedConvert('name', (v) => v as String),
      service: $checkedConvert('service', (v) => v as String),
      allowedHosts: $checkedConvert(
        'allowed_hosts',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      reason: $checkedConvert('reason', (v) => v as String),
      kind: $checkedConvert('kind', (v) => $enumDecode(_$SecretKindEnumMap, v)),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$BotSecretRequestStatusEnumEnumMap, v),
      ),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => DateTime.parse(v as String),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'botId': 'bot_id',
    'runId': 'run_id',
    'conversationId': 'conversation_id',
    'allowedHosts': 'allowed_hosts',
    'expiresAt': 'expires_at',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$BotSecretRequestToJson(BotSecretRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'org_id': instance.orgId,
      'bot_id': instance.botId,
      'run_id': instance.runId,
      'conversation_id': instance.conversationId,
      'name': instance.name,
      'service': instance.service,
      'allowed_hosts': instance.allowedHosts,
      'reason': instance.reason,
      'kind': _$SecretKindEnumMap[instance.kind]!,
      'status': _$BotSecretRequestStatusEnumEnumMap[instance.status]!,
      'expires_at': instance.expiresAt.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$SecretKindEnumMap = {
  SecretKind.plain: 'value',
  SecretKind.totp: 'totp',
};

const _$BotSecretRequestStatusEnumEnumMap = {
  BotSecretRequestStatusEnum.pending: 'pending',
  BotSecretRequestStatusEnum.fulfilled: 'fulfilled',
  BotSecretRequestStatusEnum.declined: 'declined',
  BotSecretRequestStatusEnum.expired: 'expired',
};

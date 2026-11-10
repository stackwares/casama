// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_link.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotLinkCWProxy {
  BotLink id(String id);

  BotLink botId(String botId);

  BotLink name(String name);

  BotLink status(BotLinkStatusEnum status);

  BotLink peerBotName(String? peerBotName);

  BotLink remoteUrl(String? remoteUrl);

  BotLink exchanges(int exchanges);

  BotLink createdAt(DateTime createdAt);

  BotLink activatedAt(DateTime? activatedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotLink(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotLink(...).copyWith(id: 12, name: "My name")
  /// ```
  BotLink call({
    String id,
    String botId,
    String name,
    BotLinkStatusEnum status,
    String? peerBotName,
    String? remoteUrl,
    int exchanges,
    DateTime createdAt,
    DateTime? activatedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotLink.copyWith(...)` or call `instanceOfBotLink.copyWith.fieldName(value)` for a single field.
class _$BotLinkCWProxyImpl implements _$BotLinkCWProxy {
  const _$BotLinkCWProxyImpl(this._value);

  final BotLink _value;

  @override
  BotLink id(String id) => call(id: id);

  @override
  BotLink botId(String botId) => call(botId: botId);

  @override
  BotLink name(String name) => call(name: name);

  @override
  BotLink status(BotLinkStatusEnum status) => call(status: status);

  @override
  BotLink peerBotName(String? peerBotName) => call(peerBotName: peerBotName);

  @override
  BotLink remoteUrl(String? remoteUrl) => call(remoteUrl: remoteUrl);

  @override
  BotLink exchanges(int exchanges) => call(exchanges: exchanges);

  @override
  BotLink createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  BotLink activatedAt(DateTime? activatedAt) => call(activatedAt: activatedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotLink(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotLink(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotLink call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? peerBotName = const $CopyWithPlaceholder(),
    Object? remoteUrl = const $CopyWithPlaceholder(),
    Object? exchanges = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? activatedAt = const $CopyWithPlaceholder(),
  }) {
    return BotLink(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as BotLinkStatusEnum,
      peerBotName: peerBotName == const $CopyWithPlaceholder()
          ? _value.peerBotName
          // ignore: cast_nullable_to_non_nullable
          : peerBotName as String?,
      remoteUrl: remoteUrl == const $CopyWithPlaceholder()
          ? _value.remoteUrl
          // ignore: cast_nullable_to_non_nullable
          : remoteUrl as String?,
      exchanges: exchanges == const $CopyWithPlaceholder() || exchanges == null
          ? _value.exchanges
          // ignore: cast_nullable_to_non_nullable
          : exchanges as int,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      activatedAt: activatedAt == const $CopyWithPlaceholder()
          ? _value.activatedAt
          // ignore: cast_nullable_to_non_nullable
          : activatedAt as DateTime?,
    );
  }
}

extension $BotLinkCopyWith on BotLink {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotLink.copyWith(...)` or `instanceOfBotLink.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotLinkCWProxy get copyWith => _$BotLinkCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotLink _$BotLinkFromJson(Map<String, dynamic> json) => $checkedCreate(
  'BotLink',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'bot_id',
        'name',
        'status',
        'peer_bot_name',
        'remote_url',
        'exchanges',
        'created_at',
        'activated_at',
      ],
    );
    final val = BotLink(
      id: $checkedConvert('id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$BotLinkStatusEnumEnumMap, v),
      ),
      peerBotName: $checkedConvert('peer_bot_name', (v) => v as String?),
      remoteUrl: $checkedConvert('remote_url', (v) => v as String?),
      exchanges: $checkedConvert('exchanges', (v) => (v as num).toInt()),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      activatedAt: $checkedConvert(
        'activated_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'peerBotName': 'peer_bot_name',
    'remoteUrl': 'remote_url',
    'createdAt': 'created_at',
    'activatedAt': 'activated_at',
  },
);

Map<String, dynamic> _$BotLinkToJson(BotLink instance) => <String, dynamic>{
  'id': instance.id,
  'bot_id': instance.botId,
  'name': instance.name,
  'status': _$BotLinkStatusEnumEnumMap[instance.status]!,
  'peer_bot_name': instance.peerBotName,
  'remote_url': instance.remoteUrl,
  'exchanges': instance.exchanges,
  'created_at': instance.createdAt.toIso8601String(),
  'activated_at': instance.activatedAt?.toIso8601String(),
};

const _$BotLinkStatusEnumEnumMap = {
  BotLinkStatusEnum.pending: 'pending',
  BotLinkStatusEnum.active: 'active',
  BotLinkStatusEnum.revoked: 'revoked',
};

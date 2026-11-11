// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'created_bot_link.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreatedBotLinkCWProxy {
  CreatedBotLink id(String id);

  CreatedBotLink botId(String botId);

  CreatedBotLink name(String name);

  CreatedBotLink status(CreatedBotLinkStatusEnum status);

  CreatedBotLink peerBotName(String? peerBotName);

  CreatedBotLink remoteUrl(String? remoteUrl);

  CreatedBotLink exchanges(int exchanges);

  CreatedBotLink createdAt(DateTime createdAt);

  CreatedBotLink activatedAt(DateTime? activatedAt);

  CreatedBotLink invite(String invite);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatedBotLink(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatedBotLink(...).copyWith(id: 12, name: "My name")
  /// ```
  CreatedBotLink call({
    String id,
    String botId,
    String name,
    CreatedBotLinkStatusEnum status,
    String? peerBotName,
    String? remoteUrl,
    int exchanges,
    DateTime createdAt,
    DateTime? activatedAt,
    String invite,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreatedBotLink.copyWith(...)` or call `instanceOfCreatedBotLink.copyWith.fieldName(value)` for a single field.
class _$CreatedBotLinkCWProxyImpl implements _$CreatedBotLinkCWProxy {
  const _$CreatedBotLinkCWProxyImpl(this._value);

  final CreatedBotLink _value;

  @override
  CreatedBotLink id(String id) => call(id: id);

  @override
  CreatedBotLink botId(String botId) => call(botId: botId);

  @override
  CreatedBotLink name(String name) => call(name: name);

  @override
  CreatedBotLink status(CreatedBotLinkStatusEnum status) =>
      call(status: status);

  @override
  CreatedBotLink peerBotName(String? peerBotName) =>
      call(peerBotName: peerBotName);

  @override
  CreatedBotLink remoteUrl(String? remoteUrl) => call(remoteUrl: remoteUrl);

  @override
  CreatedBotLink exchanges(int exchanges) => call(exchanges: exchanges);

  @override
  CreatedBotLink createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  CreatedBotLink activatedAt(DateTime? activatedAt) =>
      call(activatedAt: activatedAt);

  @override
  CreatedBotLink invite(String invite) => call(invite: invite);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatedBotLink(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatedBotLink(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreatedBotLink call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? peerBotName = const $CopyWithPlaceholder(),
    Object? remoteUrl = const $CopyWithPlaceholder(),
    Object? exchanges = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? activatedAt = const $CopyWithPlaceholder(),
    Object? invite = const $CopyWithPlaceholder(),
  }) {
    return CreatedBotLink(
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
          : status as CreatedBotLinkStatusEnum,
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
      invite: invite == const $CopyWithPlaceholder() || invite == null
          ? _value.invite
          // ignore: cast_nullable_to_non_nullable
          : invite as String,
    );
  }
}

extension $CreatedBotLinkCopyWith on CreatedBotLink {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreatedBotLink.copyWith(...)` or `instanceOfCreatedBotLink.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreatedBotLinkCWProxy get copyWith => _$CreatedBotLinkCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatedBotLink _$CreatedBotLinkFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CreatedBotLink',
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
            'invite',
          ],
        );
        final val = CreatedBotLink(
          id: $checkedConvert('id', (v) => v as String),
          botId: $checkedConvert('bot_id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$CreatedBotLinkStatusEnumEnumMap, v),
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
          invite: $checkedConvert('invite', (v) => v as String),
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

Map<String, dynamic> _$CreatedBotLinkToJson(CreatedBotLink instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bot_id': instance.botId,
      'name': instance.name,
      'status': _$CreatedBotLinkStatusEnumEnumMap[instance.status]!,
      'peer_bot_name': instance.peerBotName,
      'remote_url': instance.remoteUrl,
      'exchanges': instance.exchanges,
      'created_at': instance.createdAt.toIso8601String(),
      'activated_at': instance.activatedAt?.toIso8601String(),
      'invite': instance.invite,
    };

const _$CreatedBotLinkStatusEnumEnumMap = {
  CreatedBotLinkStatusEnum.pending: 'pending',
  CreatedBotLinkStatusEnum.active: 'active',
  CreatedBotLinkStatusEnum.revoked: 'revoked',
};

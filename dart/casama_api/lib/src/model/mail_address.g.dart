// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mail_address.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MailAddressCWProxy {
  MailAddress id(String id);

  MailAddress botId(String botId);

  MailAddress channelId(String channelId);

  MailAddress localPart(String localPart);

  MailAddress address(String address);

  MailAddress status(MailAddressStatusEnum status);

  MailAddress blockedSenders(List<String> blockedSenders);

  MailAddress notifyNewSenders(bool notifyNewSenders);

  MailAddress createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MailAddress(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MailAddress(...).copyWith(id: 12, name: "My name")
  /// ```
  MailAddress call({
    String id,
    String botId,
    String channelId,
    String localPart,
    String address,
    MailAddressStatusEnum status,
    List<String> blockedSenders,
    bool notifyNewSenders,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMailAddress.copyWith(...)` or call `instanceOfMailAddress.copyWith.fieldName(value)` for a single field.
class _$MailAddressCWProxyImpl implements _$MailAddressCWProxy {
  const _$MailAddressCWProxyImpl(this._value);

  final MailAddress _value;

  @override
  MailAddress id(String id) => call(id: id);

  @override
  MailAddress botId(String botId) => call(botId: botId);

  @override
  MailAddress channelId(String channelId) => call(channelId: channelId);

  @override
  MailAddress localPart(String localPart) => call(localPart: localPart);

  @override
  MailAddress address(String address) => call(address: address);

  @override
  MailAddress status(MailAddressStatusEnum status) => call(status: status);

  @override
  MailAddress blockedSenders(List<String> blockedSenders) =>
      call(blockedSenders: blockedSenders);

  @override
  MailAddress notifyNewSenders(bool notifyNewSenders) =>
      call(notifyNewSenders: notifyNewSenders);

  @override
  MailAddress createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MailAddress(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MailAddress(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MailAddress call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? channelId = const $CopyWithPlaceholder(),
    Object? localPart = const $CopyWithPlaceholder(),
    Object? address = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? blockedSenders = const $CopyWithPlaceholder(),
    Object? notifyNewSenders = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return MailAddress(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      channelId: channelId == const $CopyWithPlaceholder() || channelId == null
          ? _value.channelId
          // ignore: cast_nullable_to_non_nullable
          : channelId as String,
      localPart: localPart == const $CopyWithPlaceholder() || localPart == null
          ? _value.localPart
          // ignore: cast_nullable_to_non_nullable
          : localPart as String,
      address: address == const $CopyWithPlaceholder() || address == null
          ? _value.address
          // ignore: cast_nullable_to_non_nullable
          : address as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as MailAddressStatusEnum,
      blockedSenders:
          blockedSenders == const $CopyWithPlaceholder() ||
              blockedSenders == null
          ? _value.blockedSenders
          // ignore: cast_nullable_to_non_nullable
          : blockedSenders as List<String>,
      notifyNewSenders:
          notifyNewSenders == const $CopyWithPlaceholder() ||
              notifyNewSenders == null
          ? _value.notifyNewSenders
          // ignore: cast_nullable_to_non_nullable
          : notifyNewSenders as bool,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $MailAddressCopyWith on MailAddress {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMailAddress.copyWith(...)` or `instanceOfMailAddress.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MailAddressCWProxy get copyWith => _$MailAddressCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MailAddress _$MailAddressFromJson(Map<String, dynamic> json) => $checkedCreate(
  'MailAddress',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'bot_id',
        'channel_id',
        'local_part',
        'address',
        'status',
        'blocked_senders',
        'notify_new_senders',
        'created_at',
      ],
    );
    final val = MailAddress(
      id: $checkedConvert('id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      channelId: $checkedConvert('channel_id', (v) => v as String),
      localPart: $checkedConvert('local_part', (v) => v as String),
      address: $checkedConvert('address', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$MailAddressStatusEnumEnumMap, v),
      ),
      blockedSenders: $checkedConvert(
        'blocked_senders',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      notifyNewSenders: $checkedConvert('notify_new_senders', (v) => v as bool),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'channelId': 'channel_id',
    'localPart': 'local_part',
    'blockedSenders': 'blocked_senders',
    'notifyNewSenders': 'notify_new_senders',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$MailAddressToJson(MailAddress instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bot_id': instance.botId,
      'channel_id': instance.channelId,
      'local_part': instance.localPart,
      'address': instance.address,
      'status': _$MailAddressStatusEnumEnumMap[instance.status]!,
      'blocked_senders': instance.blockedSenders,
      'notify_new_senders': instance.notifyNewSenders,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$MailAddressStatusEnumEnumMap = {
  MailAddressStatusEnum.active: 'active',
  MailAddressStatusEnum.paused: 'paused',
  MailAddressStatusEnum.retired: 'retired',
};

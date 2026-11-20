// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_mail_address.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminMailAddressCWProxy {
  AdminMailAddress id(String id);

  AdminMailAddress address(String address);

  AdminMailAddress orgId(String? orgId);

  AdminMailAddress orgName(String orgName);

  AdminMailAddress botId(String? botId);

  AdminMailAddress botName(String botName);

  AdminMailAddress status(AdminMailAddressStatusEnum status);

  AdminMailAddress autoPaused(bool autoPaused);

  AdminMailAddress sent30d(int sent30d);

  AdminMailAddress bounced30d(int bounced30d);

  AdminMailAddress complained30d(int complained30d);

  AdminMailAddress createdAt(String createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMailAddress(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMailAddress(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminMailAddress call({
    String id,
    String address,
    String? orgId,
    String orgName,
    String? botId,
    String botName,
    AdminMailAddressStatusEnum status,
    bool autoPaused,
    int sent30d,
    int bounced30d,
    int complained30d,
    String createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminMailAddress.copyWith(...)` or call `instanceOfAdminMailAddress.copyWith.fieldName(value)` for a single field.
class _$AdminMailAddressCWProxyImpl implements _$AdminMailAddressCWProxy {
  const _$AdminMailAddressCWProxyImpl(this._value);

  final AdminMailAddress _value;

  @override
  AdminMailAddress id(String id) => call(id: id);

  @override
  AdminMailAddress address(String address) => call(address: address);

  @override
  AdminMailAddress orgId(String? orgId) => call(orgId: orgId);

  @override
  AdminMailAddress orgName(String orgName) => call(orgName: orgName);

  @override
  AdminMailAddress botId(String? botId) => call(botId: botId);

  @override
  AdminMailAddress botName(String botName) => call(botName: botName);

  @override
  AdminMailAddress status(AdminMailAddressStatusEnum status) =>
      call(status: status);

  @override
  AdminMailAddress autoPaused(bool autoPaused) => call(autoPaused: autoPaused);

  @override
  AdminMailAddress sent30d(int sent30d) => call(sent30d: sent30d);

  @override
  AdminMailAddress bounced30d(int bounced30d) => call(bounced30d: bounced30d);

  @override
  AdminMailAddress complained30d(int complained30d) =>
      call(complained30d: complained30d);

  @override
  AdminMailAddress createdAt(String createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMailAddress(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMailAddress(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminMailAddress call({
    Object? id = const $CopyWithPlaceholder(),
    Object? address = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? orgName = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? botName = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? autoPaused = const $CopyWithPlaceholder(),
    Object? sent30d = const $CopyWithPlaceholder(),
    Object? bounced30d = const $CopyWithPlaceholder(),
    Object? complained30d = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return AdminMailAddress(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      address: address == const $CopyWithPlaceholder() || address == null
          ? _value.address
          // ignore: cast_nullable_to_non_nullable
          : address as String,
      orgId: orgId == const $CopyWithPlaceholder()
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String?,
      orgName: orgName == const $CopyWithPlaceholder() || orgName == null
          ? _value.orgName
          // ignore: cast_nullable_to_non_nullable
          : orgName as String,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String?,
      botName: botName == const $CopyWithPlaceholder() || botName == null
          ? _value.botName
          // ignore: cast_nullable_to_non_nullable
          : botName as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as AdminMailAddressStatusEnum,
      autoPaused:
          autoPaused == const $CopyWithPlaceholder() || autoPaused == null
          ? _value.autoPaused
          // ignore: cast_nullable_to_non_nullable
          : autoPaused as bool,
      sent30d: sent30d == const $CopyWithPlaceholder() || sent30d == null
          ? _value.sent30d
          // ignore: cast_nullable_to_non_nullable
          : sent30d as int,
      bounced30d:
          bounced30d == const $CopyWithPlaceholder() || bounced30d == null
          ? _value.bounced30d
          // ignore: cast_nullable_to_non_nullable
          : bounced30d as int,
      complained30d:
          complained30d == const $CopyWithPlaceholder() || complained30d == null
          ? _value.complained30d
          // ignore: cast_nullable_to_non_nullable
          : complained30d as int,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as String,
    );
  }
}

extension $AdminMailAddressCopyWith on AdminMailAddress {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminMailAddress.copyWith(...)` or `instanceOfAdminMailAddress.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminMailAddressCWProxy get copyWith => _$AdminMailAddressCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminMailAddress _$AdminMailAddressFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminMailAddress',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'address',
            'org_id',
            'org_name',
            'bot_id',
            'bot_name',
            'status',
            'auto_paused',
            'sent_30d',
            'bounced_30d',
            'complained_30d',
            'created_at',
          ],
        );
        final val = AdminMailAddress(
          id: $checkedConvert('id', (v) => v as String),
          address: $checkedConvert('address', (v) => v as String),
          orgId: $checkedConvert('org_id', (v) => v as String?),
          orgName: $checkedConvert('org_name', (v) => v as String),
          botId: $checkedConvert('bot_id', (v) => v as String?),
          botName: $checkedConvert('bot_name', (v) => v as String),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$AdminMailAddressStatusEnumEnumMap, v),
          ),
          autoPaused: $checkedConvert('auto_paused', (v) => v as bool),
          sent30d: $checkedConvert('sent_30d', (v) => (v as num).toInt()),
          bounced30d: $checkedConvert('bounced_30d', (v) => (v as num).toInt()),
          complained30d: $checkedConvert(
            'complained_30d',
            (v) => (v as num).toInt(),
          ),
          createdAt: $checkedConvert('created_at', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'orgId': 'org_id',
        'orgName': 'org_name',
        'botId': 'bot_id',
        'botName': 'bot_name',
        'autoPaused': 'auto_paused',
        'sent30d': 'sent_30d',
        'bounced30d': 'bounced_30d',
        'complained30d': 'complained_30d',
        'createdAt': 'created_at',
      },
    );

Map<String, dynamic> _$AdminMailAddressToJson(AdminMailAddress instance) =>
    <String, dynamic>{
      'id': instance.id,
      'address': instance.address,
      'org_id': instance.orgId,
      'org_name': instance.orgName,
      'bot_id': instance.botId,
      'bot_name': instance.botName,
      'status': _$AdminMailAddressStatusEnumEnumMap[instance.status]!,
      'auto_paused': instance.autoPaused,
      'sent_30d': instance.sent30d,
      'bounced_30d': instance.bounced30d,
      'complained_30d': instance.complained30d,
      'created_at': instance.createdAt,
    };

const _$AdminMailAddressStatusEnumEnumMap = {
  AdminMailAddressStatusEnum.active: 'active',
  AdminMailAddressStatusEnum.paused: 'paused',
  AdminMailAddressStatusEnum.retired: 'retired',
};

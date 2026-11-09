// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_secret_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateSecretRequestCWProxy {
  CreateSecretRequest orgId(String orgId);

  CreateSecretRequest name(String name);

  CreateSecretRequest value(String value);

  CreateSecretRequest allowedHosts(List<String> allowedHosts);

  CreateSecretRequest allowedBotIds(List<String>? allowedBotIds);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateSecretRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateSecretRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateSecretRequest call({
    String orgId,
    String name,
    String value,
    List<String> allowedHosts,
    List<String>? allowedBotIds,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCreateSecretRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCreateSecretRequest.copyWith.fieldName(...)`
class _$CreateSecretRequestCWProxyImpl implements _$CreateSecretRequestCWProxy {
  const _$CreateSecretRequestCWProxyImpl(this._value);

  final CreateSecretRequest _value;

  @override
  CreateSecretRequest orgId(String orgId) => this(orgId: orgId);

  @override
  CreateSecretRequest name(String name) => this(name: name);

  @override
  CreateSecretRequest value(String value) => this(value: value);

  @override
  CreateSecretRequest allowedHosts(List<String> allowedHosts) =>
      this(allowedHosts: allowedHosts);

  @override
  CreateSecretRequest allowedBotIds(List<String>? allowedBotIds) =>
      this(allowedBotIds: allowedBotIds);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateSecretRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateSecretRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateSecretRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
    Object? allowedHosts = const $CopyWithPlaceholder(),
    Object? allowedBotIds = const $CopyWithPlaceholder(),
  }) {
    return CreateSecretRequest(
      orgId: orgId == const $CopyWithPlaceholder()
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      value: value == const $CopyWithPlaceholder()
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as String,
      allowedHosts: allowedHosts == const $CopyWithPlaceholder()
          ? _value.allowedHosts
          // ignore: cast_nullable_to_non_nullable
          : allowedHosts as List<String>,
      allowedBotIds: allowedBotIds == const $CopyWithPlaceholder()
          ? _value.allowedBotIds
          // ignore: cast_nullable_to_non_nullable
          : allowedBotIds as List<String>?,
    );
  }
}

extension $CreateSecretRequestCopyWith on CreateSecretRequest {
  /// Returns a callable class that can be used as follows: `instanceOfCreateSecretRequest.copyWith(...)` or like so:`instanceOfCreateSecretRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateSecretRequestCWProxy get copyWith =>
      _$CreateSecretRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateSecretRequest _$CreateSecretRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CreateSecretRequest',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['org_id', 'name', 'value', 'allowed_hosts'],
        );
        final val = CreateSecretRequest(
          orgId: $checkedConvert('org_id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          value: $checkedConvert('value', (v) => v as String),
          allowedHosts: $checkedConvert(
            'allowed_hosts',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          allowedBotIds: $checkedConvert(
            'allowed_bot_ids',
            (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'orgId': 'org_id',
        'allowedHosts': 'allowed_hosts',
        'allowedBotIds': 'allowed_bot_ids',
      },
    );

Map<String, dynamic> _$CreateSecretRequestToJson(
  CreateSecretRequest instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'name': instance.name,
  'value': instance.value,
  'allowed_hosts': instance.allowedHosts,
  'allowed_bot_ids': ?instance.allowedBotIds,
};

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

  CreateSecretRequest kind(SecretKind? kind);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateSecretRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateSecretRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateSecretRequest call({
    String orgId,
    String name,
    String value,
    List<String> allowedHosts,
    List<String>? allowedBotIds,
    SecretKind? kind,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateSecretRequest.copyWith(...)` or call `instanceOfCreateSecretRequest.copyWith.fieldName(value)` for a single field.
class _$CreateSecretRequestCWProxyImpl implements _$CreateSecretRequestCWProxy {
  const _$CreateSecretRequestCWProxyImpl(this._value);

  final CreateSecretRequest _value;

  @override
  CreateSecretRequest orgId(String orgId) => call(orgId: orgId);

  @override
  CreateSecretRequest name(String name) => call(name: name);

  @override
  CreateSecretRequest value(String value) => call(value: value);

  @override
  CreateSecretRequest allowedHosts(List<String> allowedHosts) =>
      call(allowedHosts: allowedHosts);

  @override
  CreateSecretRequest allowedBotIds(List<String>? allowedBotIds) =>
      call(allowedBotIds: allowedBotIds);

  @override
  CreateSecretRequest kind(SecretKind? kind) => call(kind: kind);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateSecretRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateSecretRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateSecretRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
    Object? allowedHosts = const $CopyWithPlaceholder(),
    Object? allowedBotIds = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
  }) {
    return CreateSecretRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      value: value == const $CopyWithPlaceholder() || value == null
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as String,
      allowedHosts:
          allowedHosts == const $CopyWithPlaceholder() || allowedHosts == null
          ? _value.allowedHosts
          // ignore: cast_nullable_to_non_nullable
          : allowedHosts as List<String>,
      allowedBotIds: allowedBotIds == const $CopyWithPlaceholder()
          ? _value.allowedBotIds
          // ignore: cast_nullable_to_non_nullable
          : allowedBotIds as List<String>?,
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as SecretKind?,
    );
  }
}

extension $CreateSecretRequestCopyWith on CreateSecretRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateSecretRequest.copyWith(...)` or `instanceOfCreateSecretRequest.copyWith.fieldName(...)`.
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
          kind: $checkedConvert(
            'kind',
            (v) => $enumDecodeNullable(_$SecretKindEnumMap, v),
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
  'kind': ?_$SecretKindEnumMap[instance.kind],
};

const _$SecretKindEnumMap = {
  SecretKind.plain: 'value',
  SecretKind.totp: 'totp',
};

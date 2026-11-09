// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_computer_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateComputerRequestCWProxy {
  CreateComputerRequest orgId(String orgId);

  CreateComputerRequest name(String name);

  CreateComputerRequest kind(CreateComputerRequestKindEnum kind);

  CreateComputerRequest ownerBotId(String? ownerBotId);

  CreateComputerRequest profile(CreateComputerRequestProfileEnum? profile);

  CreateComputerRequest provider(CreateComputerRequestProviderEnum? provider);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateComputerRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateComputerRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateComputerRequest call({
    String orgId,
    String name,
    CreateComputerRequestKindEnum kind,
    String? ownerBotId,
    CreateComputerRequestProfileEnum? profile,
    CreateComputerRequestProviderEnum? provider,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateComputerRequest.copyWith(...)` or call `instanceOfCreateComputerRequest.copyWith.fieldName(value)` for a single field.
class _$CreateComputerRequestCWProxyImpl
    implements _$CreateComputerRequestCWProxy {
  const _$CreateComputerRequestCWProxyImpl(this._value);

  final CreateComputerRequest _value;

  @override
  CreateComputerRequest orgId(String orgId) => call(orgId: orgId);

  @override
  CreateComputerRequest name(String name) => call(name: name);

  @override
  CreateComputerRequest kind(CreateComputerRequestKindEnum kind) =>
      call(kind: kind);

  @override
  CreateComputerRequest ownerBotId(String? ownerBotId) =>
      call(ownerBotId: ownerBotId);

  @override
  CreateComputerRequest profile(CreateComputerRequestProfileEnum? profile) =>
      call(profile: profile);

  @override
  CreateComputerRequest provider(CreateComputerRequestProviderEnum? provider) =>
      call(provider: provider);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateComputerRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateComputerRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateComputerRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? ownerBotId = const $CopyWithPlaceholder(),
    Object? profile = const $CopyWithPlaceholder(),
    Object? provider = const $CopyWithPlaceholder(),
  }) {
    return CreateComputerRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as CreateComputerRequestKindEnum,
      ownerBotId: ownerBotId == const $CopyWithPlaceholder()
          ? _value.ownerBotId
          // ignore: cast_nullable_to_non_nullable
          : ownerBotId as String?,
      profile: profile == const $CopyWithPlaceholder()
          ? _value.profile
          // ignore: cast_nullable_to_non_nullable
          : profile as CreateComputerRequestProfileEnum?,
      provider: provider == const $CopyWithPlaceholder()
          ? _value.provider
          // ignore: cast_nullable_to_non_nullable
          : provider as CreateComputerRequestProviderEnum?,
    );
  }
}

extension $CreateComputerRequestCopyWith on CreateComputerRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateComputerRequest.copyWith(...)` or `instanceOfCreateComputerRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateComputerRequestCWProxy get copyWith =>
      _$CreateComputerRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateComputerRequest _$CreateComputerRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateComputerRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['org_id', 'name', 'kind']);
  final val = CreateComputerRequest(
    orgId: $checkedConvert('org_id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    kind: $checkedConvert(
      'kind',
      (v) => $enumDecode(_$CreateComputerRequestKindEnumEnumMap, v),
    ),
    ownerBotId: $checkedConvert('owner_bot_id', (v) => v as String?),
    profile: $checkedConvert(
      'profile',
      (v) => $enumDecodeNullable(_$CreateComputerRequestProfileEnumEnumMap, v),
    ),
    provider: $checkedConvert(
      'provider',
      (v) => $enumDecodeNullable(_$CreateComputerRequestProviderEnumEnumMap, v),
    ),
  );
  return val;
}, fieldKeyMap: const {'orgId': 'org_id', 'ownerBotId': 'owner_bot_id'});

Map<String, dynamic> _$CreateComputerRequestToJson(
  CreateComputerRequest instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'name': instance.name,
  'kind': _$CreateComputerRequestKindEnumEnumMap[instance.kind]!,
  'owner_bot_id': ?instance.ownerBotId,
  'profile': ?_$CreateComputerRequestProfileEnumEnumMap[instance.profile],
  'provider': ?_$CreateComputerRequestProviderEnumEnumMap[instance.provider],
};

const _$CreateComputerRequestKindEnumEnumMap = {
  CreateComputerRequestKindEnum.team: 'team',
  CreateComputerRequestKindEnum.private: 'private',
};

const _$CreateComputerRequestProfileEnumEnumMap = {
  CreateComputerRequestProfileEnum.headless: 'headless',
  CreateComputerRequestProfileEnum.desktop: 'desktop',
};

const _$CreateComputerRequestProviderEnumEnumMap = {
  CreateComputerRequestProviderEnum.docker: 'docker',
  CreateComputerRequestProviderEnum.e2b: 'e2b',
  CreateComputerRequestProviderEnum.daytona: 'daytona',
  CreateComputerRequestProviderEnum.kasamaCloud: 'kasama-cloud',
};

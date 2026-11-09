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

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateComputerRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateComputerRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateComputerRequest call({
    String orgId,
    String name,
    CreateComputerRequestKindEnum kind,
    String? ownerBotId,
    CreateComputerRequestProfileEnum? profile,
    CreateComputerRequestProviderEnum? provider,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCreateComputerRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCreateComputerRequest.copyWith.fieldName(...)`
class _$CreateComputerRequestCWProxyImpl
    implements _$CreateComputerRequestCWProxy {
  const _$CreateComputerRequestCWProxyImpl(this._value);

  final CreateComputerRequest _value;

  @override
  CreateComputerRequest orgId(String orgId) => this(orgId: orgId);

  @override
  CreateComputerRequest name(String name) => this(name: name);

  @override
  CreateComputerRequest kind(CreateComputerRequestKindEnum kind) =>
      this(kind: kind);

  @override
  CreateComputerRequest ownerBotId(String? ownerBotId) =>
      this(ownerBotId: ownerBotId);

  @override
  CreateComputerRequest profile(CreateComputerRequestProfileEnum? profile) =>
      this(profile: profile);

  @override
  CreateComputerRequest provider(CreateComputerRequestProviderEnum? provider) =>
      this(provider: provider);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateComputerRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateComputerRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateComputerRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? ownerBotId = const $CopyWithPlaceholder(),
    Object? profile = const $CopyWithPlaceholder(),
    Object? provider = const $CopyWithPlaceholder(),
  }) {
    return CreateComputerRequest(
      orgId: orgId == const $CopyWithPlaceholder()
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      kind: kind == const $CopyWithPlaceholder()
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
  /// Returns a callable class that can be used as follows: `instanceOfCreateComputerRequest.copyWith(...)` or like so:`instanceOfCreateComputerRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateComputerRequestCWProxy get copyWith =>
      _$CreateComputerRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateComputerRequest _$CreateComputerRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CreateComputerRequest',
  json,
  ($checkedConvert) {
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
        (v) =>
            $enumDecodeNullable(_$CreateComputerRequestProfileEnumEnumMap, v),
      ),
      provider: $checkedConvert(
        'provider',
        (v) =>
            $enumDecodeNullable(_$CreateComputerRequestProviderEnumEnumMap, v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'orgId': 'org_id', 'ownerBotId': 'owner_bot_id'},
);

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
};

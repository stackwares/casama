// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_bot_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateBotRequestCWProxy {
  CreateBotRequest orgId(String orgId);

  CreateBotRequest name(String name);

  CreateBotRequest personaMd(String? personaMd);

  CreateBotRequest avatarUrl(String? avatarUrl);

  CreateBotRequest modelPolicy(ModelPolicy? modelPolicy);

  CreateBotRequest autonomy(Autonomy? autonomy);

  CreateBotRequest visibility(Visibility? visibility);

  CreateBotRequest budget(BotBudget? budget);

  CreateBotRequest templateId(String? templateId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateBotRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateBotRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateBotRequest call({
    String orgId,
    String name,
    String? personaMd,
    String? avatarUrl,
    ModelPolicy? modelPolicy,
    Autonomy? autonomy,
    Visibility? visibility,
    BotBudget? budget,
    String? templateId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCreateBotRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCreateBotRequest.copyWith.fieldName(...)`
class _$CreateBotRequestCWProxyImpl implements _$CreateBotRequestCWProxy {
  const _$CreateBotRequestCWProxyImpl(this._value);

  final CreateBotRequest _value;

  @override
  CreateBotRequest orgId(String orgId) => this(orgId: orgId);

  @override
  CreateBotRequest name(String name) => this(name: name);

  @override
  CreateBotRequest personaMd(String? personaMd) => this(personaMd: personaMd);

  @override
  CreateBotRequest avatarUrl(String? avatarUrl) => this(avatarUrl: avatarUrl);

  @override
  CreateBotRequest modelPolicy(ModelPolicy? modelPolicy) =>
      this(modelPolicy: modelPolicy);

  @override
  CreateBotRequest autonomy(Autonomy? autonomy) => this(autonomy: autonomy);

  @override
  CreateBotRequest visibility(Visibility? visibility) =>
      this(visibility: visibility);

  @override
  CreateBotRequest budget(BotBudget? budget) => this(budget: budget);

  @override
  CreateBotRequest templateId(String? templateId) =>
      this(templateId: templateId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateBotRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateBotRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateBotRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? personaMd = const $CopyWithPlaceholder(),
    Object? avatarUrl = const $CopyWithPlaceholder(),
    Object? modelPolicy = const $CopyWithPlaceholder(),
    Object? autonomy = const $CopyWithPlaceholder(),
    Object? visibility = const $CopyWithPlaceholder(),
    Object? budget = const $CopyWithPlaceholder(),
    Object? templateId = const $CopyWithPlaceholder(),
  }) {
    return CreateBotRequest(
      orgId: orgId == const $CopyWithPlaceholder()
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      personaMd: personaMd == const $CopyWithPlaceholder()
          ? _value.personaMd
          // ignore: cast_nullable_to_non_nullable
          : personaMd as String?,
      avatarUrl: avatarUrl == const $CopyWithPlaceholder()
          ? _value.avatarUrl
          // ignore: cast_nullable_to_non_nullable
          : avatarUrl as String?,
      modelPolicy: modelPolicy == const $CopyWithPlaceholder()
          ? _value.modelPolicy
          // ignore: cast_nullable_to_non_nullable
          : modelPolicy as ModelPolicy?,
      autonomy: autonomy == const $CopyWithPlaceholder()
          ? _value.autonomy
          // ignore: cast_nullable_to_non_nullable
          : autonomy as Autonomy?,
      visibility: visibility == const $CopyWithPlaceholder()
          ? _value.visibility
          // ignore: cast_nullable_to_non_nullable
          : visibility as Visibility?,
      budget: budget == const $CopyWithPlaceholder()
          ? _value.budget
          // ignore: cast_nullable_to_non_nullable
          : budget as BotBudget?,
      templateId: templateId == const $CopyWithPlaceholder()
          ? _value.templateId
          // ignore: cast_nullable_to_non_nullable
          : templateId as String?,
    );
  }
}

extension $CreateBotRequestCopyWith on CreateBotRequest {
  /// Returns a callable class that can be used as follows: `instanceOfCreateBotRequest.copyWith(...)` or like so:`instanceOfCreateBotRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateBotRequestCWProxy get copyWith => _$CreateBotRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateBotRequest _$CreateBotRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CreateBotRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['org_id', 'name']);
    final val = CreateBotRequest(
      orgId: $checkedConvert('org_id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      personaMd: $checkedConvert('persona_md', (v) => v as String?),
      avatarUrl: $checkedConvert('avatar_url', (v) => v as String?),
      modelPolicy: $checkedConvert(
        'model_policy',
        (v) =>
            v == null ? null : ModelPolicy.fromJson(v as Map<String, dynamic>),
      ),
      autonomy: $checkedConvert(
        'autonomy',
        (v) => $enumDecodeNullable(_$AutonomyEnumMap, v),
      ),
      visibility: $checkedConvert(
        'visibility',
        (v) => $enumDecodeNullable(_$VisibilityEnumMap, v),
      ),
      budget: $checkedConvert(
        'budget',
        (v) => v == null ? null : BotBudget.fromJson(v as Map<String, dynamic>),
      ),
      templateId: $checkedConvert('template_id', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'personaMd': 'persona_md',
    'avatarUrl': 'avatar_url',
    'modelPolicy': 'model_policy',
    'templateId': 'template_id',
  },
);

Map<String, dynamic> _$CreateBotRequestToJson(CreateBotRequest instance) =>
    <String, dynamic>{
      'org_id': instance.orgId,
      'name': instance.name,
      'persona_md': ?instance.personaMd,
      'avatar_url': ?instance.avatarUrl,
      'model_policy': ?instance.modelPolicy?.toJson(),
      'autonomy': ?_$AutonomyEnumMap[instance.autonomy],
      'visibility': ?_$VisibilityEnumMap[instance.visibility],
      'budget': ?instance.budget?.toJson(),
      'template_id': ?instance.templateId,
    };

const _$AutonomyEnumMap = {
  Autonomy.askAlways: 'ask_always',
  Autonomy.askRisky: 'ask_risky',
  Autonomy.autonomous: 'autonomous',
};

const _$VisibilityEnumMap = {
  Visibility.private: 'private',
  Visibility.team: 'team',
};

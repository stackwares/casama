// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotCWProxy {
  Bot id(String id);

  Bot orgId(String orgId);

  Bot name(String name);

  Bot avatarUrl(String? avatarUrl);

  Bot personaMd(String personaMd);

  Bot modelPolicy(ModelPolicy modelPolicy);

  Bot autonomy(Autonomy autonomy);

  Bot visibility(Visibility visibility);

  Bot budget(BotBudget budget);

  Bot status(BotStatusEnum status);

  Bot defaultComputerId(String? defaultComputerId);

  Bot createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Bot(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Bot(...).copyWith(id: 12, name: "My name")
  /// ```
  Bot call({
    String id,
    String orgId,
    String name,
    String? avatarUrl,
    String personaMd,
    ModelPolicy modelPolicy,
    Autonomy autonomy,
    Visibility visibility,
    BotBudget budget,
    BotStatusEnum status,
    String? defaultComputerId,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBot.copyWith(...)` or call `instanceOfBot.copyWith.fieldName(value)` for a single field.
class _$BotCWProxyImpl implements _$BotCWProxy {
  const _$BotCWProxyImpl(this._value);

  final Bot _value;

  @override
  Bot id(String id) => call(id: id);

  @override
  Bot orgId(String orgId) => call(orgId: orgId);

  @override
  Bot name(String name) => call(name: name);

  @override
  Bot avatarUrl(String? avatarUrl) => call(avatarUrl: avatarUrl);

  @override
  Bot personaMd(String personaMd) => call(personaMd: personaMd);

  @override
  Bot modelPolicy(ModelPolicy modelPolicy) => call(modelPolicy: modelPolicy);

  @override
  Bot autonomy(Autonomy autonomy) => call(autonomy: autonomy);

  @override
  Bot visibility(Visibility visibility) => call(visibility: visibility);

  @override
  Bot budget(BotBudget budget) => call(budget: budget);

  @override
  Bot status(BotStatusEnum status) => call(status: status);

  @override
  Bot defaultComputerId(String? defaultComputerId) =>
      call(defaultComputerId: defaultComputerId);

  @override
  Bot createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Bot(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Bot(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Bot call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? avatarUrl = const $CopyWithPlaceholder(),
    Object? personaMd = const $CopyWithPlaceholder(),
    Object? modelPolicy = const $CopyWithPlaceholder(),
    Object? autonomy = const $CopyWithPlaceholder(),
    Object? visibility = const $CopyWithPlaceholder(),
    Object? budget = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? defaultComputerId = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Bot(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      avatarUrl: avatarUrl == const $CopyWithPlaceholder()
          ? _value.avatarUrl
          // ignore: cast_nullable_to_non_nullable
          : avatarUrl as String?,
      personaMd: personaMd == const $CopyWithPlaceholder() || personaMd == null
          ? _value.personaMd
          // ignore: cast_nullable_to_non_nullable
          : personaMd as String,
      modelPolicy:
          modelPolicy == const $CopyWithPlaceholder() || modelPolicy == null
          ? _value.modelPolicy
          // ignore: cast_nullable_to_non_nullable
          : modelPolicy as ModelPolicy,
      autonomy: autonomy == const $CopyWithPlaceholder() || autonomy == null
          ? _value.autonomy
          // ignore: cast_nullable_to_non_nullable
          : autonomy as Autonomy,
      visibility:
          visibility == const $CopyWithPlaceholder() || visibility == null
          ? _value.visibility
          // ignore: cast_nullable_to_non_nullable
          : visibility as Visibility,
      budget: budget == const $CopyWithPlaceholder() || budget == null
          ? _value.budget
          // ignore: cast_nullable_to_non_nullable
          : budget as BotBudget,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as BotStatusEnum,
      defaultComputerId: defaultComputerId == const $CopyWithPlaceholder()
          ? _value.defaultComputerId
          // ignore: cast_nullable_to_non_nullable
          : defaultComputerId as String?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $BotCopyWith on Bot {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBot.copyWith(...)` or `instanceOfBot.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotCWProxy get copyWith => _$BotCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Bot _$BotFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Bot',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'org_id',
        'name',
        'avatar_url',
        'persona_md',
        'model_policy',
        'autonomy',
        'visibility',
        'budget',
        'status',
        'default_computer_id',
        'created_at',
      ],
    );
    final val = Bot(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      avatarUrl: $checkedConvert('avatar_url', (v) => v as String?),
      personaMd: $checkedConvert('persona_md', (v) => v as String),
      modelPolicy: $checkedConvert(
        'model_policy',
        (v) => ModelPolicy.fromJson(v as Map<String, dynamic>),
      ),
      autonomy: $checkedConvert(
        'autonomy',
        (v) => $enumDecode(_$AutonomyEnumMap, v),
      ),
      visibility: $checkedConvert(
        'visibility',
        (v) => $enumDecode(_$VisibilityEnumMap, v),
      ),
      budget: $checkedConvert(
        'budget',
        (v) => BotBudget.fromJson(v as Map<String, dynamic>),
      ),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$BotStatusEnumEnumMap, v),
      ),
      defaultComputerId: $checkedConvert(
        'default_computer_id',
        (v) => v as String?,
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
    'avatarUrl': 'avatar_url',
    'personaMd': 'persona_md',
    'modelPolicy': 'model_policy',
    'defaultComputerId': 'default_computer_id',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$BotToJson(Bot instance) => <String, dynamic>{
  'id': instance.id,
  'org_id': instance.orgId,
  'name': instance.name,
  'avatar_url': instance.avatarUrl,
  'persona_md': instance.personaMd,
  'model_policy': instance.modelPolicy.toJson(),
  'autonomy': _$AutonomyEnumMap[instance.autonomy]!,
  'visibility': _$VisibilityEnumMap[instance.visibility]!,
  'budget': instance.budget.toJson(),
  'status': _$BotStatusEnumEnumMap[instance.status]!,
  'default_computer_id': instance.defaultComputerId,
  'created_at': instance.createdAt.toIso8601String(),
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

const _$BotStatusEnumEnumMap = {
  BotStatusEnum.idle: 'idle',
  BotStatusEnum.working: 'working',
  BotStatusEnum.waiting: 'waiting',
  BotStatusEnum.disabled: 'disabled',
};

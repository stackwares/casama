// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_action_rule_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateActionRuleRequestCWProxy {
  CreateActionRuleRequest orgId(String orgId);

  CreateActionRuleRequest botId(String? botId);

  CreateActionRuleRequest matchKind(
    CreateActionRuleRequestMatchKindEnum matchKind,
  );

  CreateActionRuleRequest matchValue(String matchValue);

  CreateActionRuleRequest target(ActionRuleTarget? target);

  CreateActionRuleRequest rule(CreateActionRuleRequestRuleEnum rule);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateActionRuleRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateActionRuleRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateActionRuleRequest call({
    String orgId,
    String? botId,
    CreateActionRuleRequestMatchKindEnum matchKind,
    String matchValue,
    ActionRuleTarget? target,
    CreateActionRuleRequestRuleEnum rule,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateActionRuleRequest.copyWith(...)` or call `instanceOfCreateActionRuleRequest.copyWith.fieldName(value)` for a single field.
class _$CreateActionRuleRequestCWProxyImpl
    implements _$CreateActionRuleRequestCWProxy {
  const _$CreateActionRuleRequestCWProxyImpl(this._value);

  final CreateActionRuleRequest _value;

  @override
  CreateActionRuleRequest orgId(String orgId) => call(orgId: orgId);

  @override
  CreateActionRuleRequest botId(String? botId) => call(botId: botId);

  @override
  CreateActionRuleRequest matchKind(
    CreateActionRuleRequestMatchKindEnum matchKind,
  ) => call(matchKind: matchKind);

  @override
  CreateActionRuleRequest matchValue(String matchValue) =>
      call(matchValue: matchValue);

  @override
  CreateActionRuleRequest target(ActionRuleTarget? target) =>
      call(target: target);

  @override
  CreateActionRuleRequest rule(CreateActionRuleRequestRuleEnum rule) =>
      call(rule: rule);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateActionRuleRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateActionRuleRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateActionRuleRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? matchKind = const $CopyWithPlaceholder(),
    Object? matchValue = const $CopyWithPlaceholder(),
    Object? target = const $CopyWithPlaceholder(),
    Object? rule = const $CopyWithPlaceholder(),
  }) {
    return CreateActionRuleRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String?,
      matchKind: matchKind == const $CopyWithPlaceholder() || matchKind == null
          ? _value.matchKind
          // ignore: cast_nullable_to_non_nullable
          : matchKind as CreateActionRuleRequestMatchKindEnum,
      matchValue:
          matchValue == const $CopyWithPlaceholder() || matchValue == null
          ? _value.matchValue
          // ignore: cast_nullable_to_non_nullable
          : matchValue as String,
      target: target == const $CopyWithPlaceholder()
          ? _value.target
          // ignore: cast_nullable_to_non_nullable
          : target as ActionRuleTarget?,
      rule: rule == const $CopyWithPlaceholder() || rule == null
          ? _value.rule
          // ignore: cast_nullable_to_non_nullable
          : rule as CreateActionRuleRequestRuleEnum,
    );
  }
}

extension $CreateActionRuleRequestCopyWith on CreateActionRuleRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateActionRuleRequest.copyWith(...)` or `instanceOfCreateActionRuleRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateActionRuleRequestCWProxy get copyWith =>
      _$CreateActionRuleRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateActionRuleRequest _$CreateActionRuleRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CreateActionRuleRequest',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['org_id', 'match_kind', 'match_value', 'rule'],
    );
    final val = CreateActionRuleRequest(
      orgId: $checkedConvert('org_id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String?),
      matchKind: $checkedConvert(
        'match_kind',
        (v) => $enumDecode(_$CreateActionRuleRequestMatchKindEnumEnumMap, v),
      ),
      matchValue: $checkedConvert('match_value', (v) => v as String),
      target: $checkedConvert(
        'target',
        (v) => v == null
            ? null
            : ActionRuleTarget.fromJson(v as Map<String, dynamic>),
      ),
      rule: $checkedConvert(
        'rule',
        (v) => $enumDecode(_$CreateActionRuleRequestRuleEnumEnumMap, v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'botId': 'bot_id',
    'matchKind': 'match_kind',
    'matchValue': 'match_value',
  },
);

Map<String, dynamic> _$CreateActionRuleRequestToJson(
  CreateActionRuleRequest instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'bot_id': ?instance.botId,
  'match_kind':
      _$CreateActionRuleRequestMatchKindEnumEnumMap[instance.matchKind]!,
  'match_value': instance.matchValue,
  'target': ?instance.target?.toJson(),
  'rule': _$CreateActionRuleRequestRuleEnumEnumMap[instance.rule]!,
};

const _$CreateActionRuleRequestMatchKindEnumEnumMap = {
  CreateActionRuleRequestMatchKindEnum.tool: 'tool',
  CreateActionRuleRequestMatchKindEnum.group: 'group',
  CreateActionRuleRequestMatchKindEnum.category: 'category',
};

const _$CreateActionRuleRequestRuleEnumEnumMap = {
  CreateActionRuleRequestRuleEnum.allow: 'allow',
  CreateActionRuleRequestRuleEnum.allowWithinLimits: 'allow_within_limits',
  CreateActionRuleRequestRuleEnum.ask: 'ask',
  CreateActionRuleRequestRuleEnum.handOff: 'hand_off',
};

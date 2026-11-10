// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_rule.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ActionRuleCWProxy {
  ActionRule id(String id);

  ActionRule orgId(String orgId);

  ActionRule botId(String? botId);

  ActionRule matchKind(ActionRuleMatchKindEnum matchKind);

  ActionRule matchValue(String matchValue);

  ActionRule target(ActionRuleTarget? target);

  ActionRule rule(ActionRuleRuleEnum rule);

  ActionRule preview(String preview);

  ActionRule createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActionRule(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActionRule(...).copyWith(id: 12, name: "My name")
  /// ```
  ActionRule call({
    String id,
    String orgId,
    String? botId,
    ActionRuleMatchKindEnum matchKind,
    String matchValue,
    ActionRuleTarget? target,
    ActionRuleRuleEnum rule,
    String preview,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfActionRule.copyWith(...)` or call `instanceOfActionRule.copyWith.fieldName(value)` for a single field.
class _$ActionRuleCWProxyImpl implements _$ActionRuleCWProxy {
  const _$ActionRuleCWProxyImpl(this._value);

  final ActionRule _value;

  @override
  ActionRule id(String id) => call(id: id);

  @override
  ActionRule orgId(String orgId) => call(orgId: orgId);

  @override
  ActionRule botId(String? botId) => call(botId: botId);

  @override
  ActionRule matchKind(ActionRuleMatchKindEnum matchKind) =>
      call(matchKind: matchKind);

  @override
  ActionRule matchValue(String matchValue) => call(matchValue: matchValue);

  @override
  ActionRule target(ActionRuleTarget? target) => call(target: target);

  @override
  ActionRule rule(ActionRuleRuleEnum rule) => call(rule: rule);

  @override
  ActionRule preview(String preview) => call(preview: preview);

  @override
  ActionRule createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActionRule(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActionRule(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ActionRule call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? matchKind = const $CopyWithPlaceholder(),
    Object? matchValue = const $CopyWithPlaceholder(),
    Object? target = const $CopyWithPlaceholder(),
    Object? rule = const $CopyWithPlaceholder(),
    Object? preview = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return ActionRule(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
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
          : matchKind as ActionRuleMatchKindEnum,
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
          : rule as ActionRuleRuleEnum,
      preview: preview == const $CopyWithPlaceholder() || preview == null
          ? _value.preview
          // ignore: cast_nullable_to_non_nullable
          : preview as String,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $ActionRuleCopyWith on ActionRule {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfActionRule.copyWith(...)` or `instanceOfActionRule.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ActionRuleCWProxy get copyWith => _$ActionRuleCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionRule _$ActionRuleFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ActionRule',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'org_id',
        'bot_id',
        'match_kind',
        'match_value',
        'target',
        'rule',
        'preview',
        'created_at',
      ],
    );
    final val = ActionRule(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String?),
      matchKind: $checkedConvert(
        'match_kind',
        (v) => $enumDecode(_$ActionRuleMatchKindEnumEnumMap, v),
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
        (v) => $enumDecode(_$ActionRuleRuleEnumEnumMap, v),
      ),
      preview: $checkedConvert('preview', (v) => v as String),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'botId': 'bot_id',
    'matchKind': 'match_kind',
    'matchValue': 'match_value',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$ActionRuleToJson(ActionRule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'org_id': instance.orgId,
      'bot_id': instance.botId,
      'match_kind': _$ActionRuleMatchKindEnumEnumMap[instance.matchKind]!,
      'match_value': instance.matchValue,
      'target': instance.target?.toJson(),
      'rule': _$ActionRuleRuleEnumEnumMap[instance.rule]!,
      'preview': instance.preview,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$ActionRuleMatchKindEnumEnumMap = {
  ActionRuleMatchKindEnum.tool: 'tool',
  ActionRuleMatchKindEnum.group: 'group',
  ActionRuleMatchKindEnum.category: 'category',
};

const _$ActionRuleRuleEnumEnumMap = {
  ActionRuleRuleEnum.allow: 'allow',
  ActionRuleRuleEnum.allowWithinLimits: 'allow_within_limits',
  ActionRuleRuleEnum.ask: 'ask',
  ActionRuleRuleEnum.handOff: 'hand_off',
};

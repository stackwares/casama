// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_bot_preview_rules_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackBotPreviewRulesInnerCWProxy {
  PackBotPreviewRulesInner matchKind(
    PackBotPreviewRulesInnerMatchKindEnum matchKind,
  );

  PackBotPreviewRulesInner matchValue(String matchValue);

  PackBotPreviewRulesInner rule(PackBotPreviewRulesInnerRuleEnum rule);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackBotPreviewRulesInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackBotPreviewRulesInner(...).copyWith(id: 12, name: "My name")
  /// ```
  PackBotPreviewRulesInner call({
    PackBotPreviewRulesInnerMatchKindEnum matchKind,
    String matchValue,
    PackBotPreviewRulesInnerRuleEnum rule,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackBotPreviewRulesInner.copyWith(...)` or call `instanceOfPackBotPreviewRulesInner.copyWith.fieldName(value)` for a single field.
class _$PackBotPreviewRulesInnerCWProxyImpl
    implements _$PackBotPreviewRulesInnerCWProxy {
  const _$PackBotPreviewRulesInnerCWProxyImpl(this._value);

  final PackBotPreviewRulesInner _value;

  @override
  PackBotPreviewRulesInner matchKind(
    PackBotPreviewRulesInnerMatchKindEnum matchKind,
  ) => call(matchKind: matchKind);

  @override
  PackBotPreviewRulesInner matchValue(String matchValue) =>
      call(matchValue: matchValue);

  @override
  PackBotPreviewRulesInner rule(PackBotPreviewRulesInnerRuleEnum rule) =>
      call(rule: rule);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackBotPreviewRulesInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackBotPreviewRulesInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackBotPreviewRulesInner call({
    Object? matchKind = const $CopyWithPlaceholder(),
    Object? matchValue = const $CopyWithPlaceholder(),
    Object? rule = const $CopyWithPlaceholder(),
  }) {
    return PackBotPreviewRulesInner(
      matchKind: matchKind == const $CopyWithPlaceholder() || matchKind == null
          ? _value.matchKind
          // ignore: cast_nullable_to_non_nullable
          : matchKind as PackBotPreviewRulesInnerMatchKindEnum,
      matchValue:
          matchValue == const $CopyWithPlaceholder() || matchValue == null
          ? _value.matchValue
          // ignore: cast_nullable_to_non_nullable
          : matchValue as String,
      rule: rule == const $CopyWithPlaceholder() || rule == null
          ? _value.rule
          // ignore: cast_nullable_to_non_nullable
          : rule as PackBotPreviewRulesInnerRuleEnum,
    );
  }
}

extension $PackBotPreviewRulesInnerCopyWith on PackBotPreviewRulesInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackBotPreviewRulesInner.copyWith(...)` or `instanceOfPackBotPreviewRulesInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackBotPreviewRulesInnerCWProxy get copyWith =>
      _$PackBotPreviewRulesInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackBotPreviewRulesInner _$PackBotPreviewRulesInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PackBotPreviewRulesInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['match_kind', 'match_value', 'rule']);
  final val = PackBotPreviewRulesInner(
    matchKind: $checkedConvert(
      'match_kind',
      (v) => $enumDecode(_$PackBotPreviewRulesInnerMatchKindEnumEnumMap, v),
    ),
    matchValue: $checkedConvert('match_value', (v) => v as String),
    rule: $checkedConvert(
      'rule',
      (v) => $enumDecode(_$PackBotPreviewRulesInnerRuleEnumEnumMap, v),
    ),
  );
  return val;
}, fieldKeyMap: const {'matchKind': 'match_kind', 'matchValue': 'match_value'});

Map<String, dynamic> _$PackBotPreviewRulesInnerToJson(
  PackBotPreviewRulesInner instance,
) => <String, dynamic>{
  'match_kind':
      _$PackBotPreviewRulesInnerMatchKindEnumEnumMap[instance.matchKind]!,
  'match_value': instance.matchValue,
  'rule': _$PackBotPreviewRulesInnerRuleEnumEnumMap[instance.rule]!,
};

const _$PackBotPreviewRulesInnerMatchKindEnumEnumMap = {
  PackBotPreviewRulesInnerMatchKindEnum.tool: 'tool',
  PackBotPreviewRulesInnerMatchKindEnum.group: 'group',
  PackBotPreviewRulesInnerMatchKindEnum.category: 'category',
};

const _$PackBotPreviewRulesInnerRuleEnumEnumMap = {
  PackBotPreviewRulesInnerRuleEnum.ask: 'ask',
  PackBotPreviewRulesInnerRuleEnum.handOff: 'hand_off',
};

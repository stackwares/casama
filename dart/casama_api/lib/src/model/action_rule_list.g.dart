// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_rule_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ActionRuleListCWProxy {
  ActionRuleList items(List<ActionRule> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActionRuleList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActionRuleList(...).copyWith(id: 12, name: "My name")
  /// ```
  ActionRuleList call({List<ActionRule> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfActionRuleList.copyWith(...)` or call `instanceOfActionRuleList.copyWith.fieldName(value)` for a single field.
class _$ActionRuleListCWProxyImpl implements _$ActionRuleListCWProxy {
  const _$ActionRuleListCWProxyImpl(this._value);

  final ActionRuleList _value;

  @override
  ActionRuleList items(List<ActionRule> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActionRuleList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActionRuleList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ActionRuleList call({Object? items = const $CopyWithPlaceholder()}) {
    return ActionRuleList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<ActionRule>,
    );
  }
}

extension $ActionRuleListCopyWith on ActionRuleList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfActionRuleList.copyWith(...)` or `instanceOfActionRuleList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ActionRuleListCWProxy get copyWith => _$ActionRuleListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionRuleList _$ActionRuleListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ActionRuleList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ActionRuleList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => ActionRule.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ActionRuleListToJson(ActionRuleList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

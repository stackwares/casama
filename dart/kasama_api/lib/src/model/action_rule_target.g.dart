// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_rule_target.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ActionRuleTargetCWProxy {
  ActionRuleTarget domains(List<String>? domains);

  ActionRuleTarget recipients(List<String>? recipients);

  ActionRuleTarget maxAmount(num? maxAmount);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActionRuleTarget(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActionRuleTarget(...).copyWith(id: 12, name: "My name")
  /// ```
  ActionRuleTarget call({
    List<String>? domains,
    List<String>? recipients,
    num? maxAmount,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfActionRuleTarget.copyWith(...)` or call `instanceOfActionRuleTarget.copyWith.fieldName(value)` for a single field.
class _$ActionRuleTargetCWProxyImpl implements _$ActionRuleTargetCWProxy {
  const _$ActionRuleTargetCWProxyImpl(this._value);

  final ActionRuleTarget _value;

  @override
  ActionRuleTarget domains(List<String>? domains) => call(domains: domains);

  @override
  ActionRuleTarget recipients(List<String>? recipients) =>
      call(recipients: recipients);

  @override
  ActionRuleTarget maxAmount(num? maxAmount) => call(maxAmount: maxAmount);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActionRuleTarget(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActionRuleTarget(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ActionRuleTarget call({
    Object? domains = const $CopyWithPlaceholder(),
    Object? recipients = const $CopyWithPlaceholder(),
    Object? maxAmount = const $CopyWithPlaceholder(),
  }) {
    return ActionRuleTarget(
      domains: domains == const $CopyWithPlaceholder()
          ? _value.domains
          // ignore: cast_nullable_to_non_nullable
          : domains as List<String>?,
      recipients: recipients == const $CopyWithPlaceholder()
          ? _value.recipients
          // ignore: cast_nullable_to_non_nullable
          : recipients as List<String>?,
      maxAmount: maxAmount == const $CopyWithPlaceholder()
          ? _value.maxAmount
          // ignore: cast_nullable_to_non_nullable
          : maxAmount as num?,
    );
  }
}

extension $ActionRuleTargetCopyWith on ActionRuleTarget {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfActionRuleTarget.copyWith(...)` or `instanceOfActionRuleTarget.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ActionRuleTargetCWProxy get copyWith => _$ActionRuleTargetCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionRuleTarget _$ActionRuleTargetFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ActionRuleTarget', json, ($checkedConvert) {
      final val = ActionRuleTarget(
        domains: $checkedConvert(
          'domains',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        recipients: $checkedConvert(
          'recipients',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        maxAmount: $checkedConvert('max_amount', (v) => v as num?),
      );
      return val;
    }, fieldKeyMap: const {'maxAmount': 'max_amount'});

Map<String, dynamic> _$ActionRuleTargetToJson(ActionRuleTarget instance) =>
    <String, dynamic>{
      'domains': ?instance.domains,
      'recipients': ?instance.recipients,
      'max_amount': ?instance.maxAmount,
    };

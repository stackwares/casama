// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_rule.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedRuleCWProxy {
  DeletedRule deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedRule(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedRule(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedRule call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedRule.copyWith(...)` or call `instanceOfDeletedRule.copyWith.fieldName(value)` for a single field.
class _$DeletedRuleCWProxyImpl implements _$DeletedRuleCWProxy {
  const _$DeletedRuleCWProxyImpl(this._value);

  final DeletedRule _value;

  @override
  DeletedRule deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedRule(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedRule(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedRule call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedRule(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedRuleCopyWith on DeletedRule {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedRule.copyWith(...)` or `instanceOfDeletedRule.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedRuleCWProxy get copyWith => _$DeletedRuleCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedRule _$DeletedRuleFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedRule', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedRule(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedRuleToJson(DeletedRule instance) =>
    <String, dynamic>{'deleted': instance.deleted};

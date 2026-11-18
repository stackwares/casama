// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ApprovalListCWProxy {
  ApprovalList items(List<Approval> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ApprovalList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ApprovalList(...).copyWith(id: 12, name: "My name")
  /// ```
  ApprovalList call({List<Approval> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfApprovalList.copyWith(...)` or call `instanceOfApprovalList.copyWith.fieldName(value)` for a single field.
class _$ApprovalListCWProxyImpl implements _$ApprovalListCWProxy {
  const _$ApprovalListCWProxyImpl(this._value);

  final ApprovalList _value;

  @override
  ApprovalList items(List<Approval> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ApprovalList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ApprovalList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ApprovalList call({Object? items = const $CopyWithPlaceholder()}) {
    return ApprovalList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Approval>,
    );
  }
}

extension $ApprovalListCopyWith on ApprovalList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfApprovalList.copyWith(...)` or `instanceOfApprovalList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ApprovalListCWProxy get copyWith => _$ApprovalListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApprovalList _$ApprovalListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ApprovalList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ApprovalList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Approval.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ApprovalListToJson(ApprovalList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

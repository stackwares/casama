// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ApprovalListCWProxy {
  ApprovalList items(List<Approval> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ApprovalList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ApprovalList(...).copyWith(id: 12, name: "My name")
  /// ````
  ApprovalList call({List<Approval> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfApprovalList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfApprovalList.copyWith.fieldName(...)`
class _$ApprovalListCWProxyImpl implements _$ApprovalListCWProxy {
  const _$ApprovalListCWProxyImpl(this._value);

  final ApprovalList _value;

  @override
  ApprovalList items(List<Approval> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ApprovalList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ApprovalList(...).copyWith(id: 12, name: "My name")
  /// ````
  ApprovalList call({Object? items = const $CopyWithPlaceholder()}) {
    return ApprovalList(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Approval>,
    );
  }
}

extension $ApprovalListCopyWith on ApprovalList {
  /// Returns a callable class that can be used as follows: `instanceOfApprovalList.copyWith(...)` or like so:`instanceOfApprovalList.copyWith.fieldName(...)`.
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

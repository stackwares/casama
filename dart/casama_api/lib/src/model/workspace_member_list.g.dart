// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_member_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WorkspaceMemberListCWProxy {
  WorkspaceMemberList items(List<WorkspaceMember> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WorkspaceMemberList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WorkspaceMemberList(...).copyWith(id: 12, name: "My name")
  /// ```
  WorkspaceMemberList call({List<WorkspaceMember> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWorkspaceMemberList.copyWith(...)` or call `instanceOfWorkspaceMemberList.copyWith.fieldName(value)` for a single field.
class _$WorkspaceMemberListCWProxyImpl implements _$WorkspaceMemberListCWProxy {
  const _$WorkspaceMemberListCWProxyImpl(this._value);

  final WorkspaceMemberList _value;

  @override
  WorkspaceMemberList items(List<WorkspaceMember> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WorkspaceMemberList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WorkspaceMemberList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WorkspaceMemberList call({Object? items = const $CopyWithPlaceholder()}) {
    return WorkspaceMemberList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<WorkspaceMember>,
    );
  }
}

extension $WorkspaceMemberListCopyWith on WorkspaceMemberList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWorkspaceMemberList.copyWith(...)` or `instanceOfWorkspaceMemberList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WorkspaceMemberListCWProxy get copyWith =>
      _$WorkspaceMemberListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkspaceMemberList _$WorkspaceMemberListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WorkspaceMemberList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = WorkspaceMemberList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => WorkspaceMember.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$WorkspaceMemberListToJson(
  WorkspaceMemberList instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

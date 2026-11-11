// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_badge_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WorkspaceBadgeListCWProxy {
  WorkspaceBadgeList items(List<WorkspaceBadge> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WorkspaceBadgeList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WorkspaceBadgeList(...).copyWith(id: 12, name: "My name")
  /// ```
  WorkspaceBadgeList call({List<WorkspaceBadge> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWorkspaceBadgeList.copyWith(...)` or call `instanceOfWorkspaceBadgeList.copyWith.fieldName(value)` for a single field.
class _$WorkspaceBadgeListCWProxyImpl implements _$WorkspaceBadgeListCWProxy {
  const _$WorkspaceBadgeListCWProxyImpl(this._value);

  final WorkspaceBadgeList _value;

  @override
  WorkspaceBadgeList items(List<WorkspaceBadge> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WorkspaceBadgeList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WorkspaceBadgeList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WorkspaceBadgeList call({Object? items = const $CopyWithPlaceholder()}) {
    return WorkspaceBadgeList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<WorkspaceBadge>,
    );
  }
}

extension $WorkspaceBadgeListCopyWith on WorkspaceBadgeList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWorkspaceBadgeList.copyWith(...)` or `instanceOfWorkspaceBadgeList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WorkspaceBadgeListCWProxy get copyWith =>
      _$WorkspaceBadgeListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkspaceBadgeList _$WorkspaceBadgeListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WorkspaceBadgeList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = WorkspaceBadgeList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => WorkspaceBadge.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$WorkspaceBadgeListToJson(WorkspaceBadgeList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'joinable_workspace_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$JoinableWorkspaceListCWProxy {
  JoinableWorkspaceList items(List<JoinableWorkspace> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `JoinableWorkspaceList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// JoinableWorkspaceList(...).copyWith(id: 12, name: "My name")
  /// ```
  JoinableWorkspaceList call({List<JoinableWorkspace> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfJoinableWorkspaceList.copyWith(...)` or call `instanceOfJoinableWorkspaceList.copyWith.fieldName(value)` for a single field.
class _$JoinableWorkspaceListCWProxyImpl
    implements _$JoinableWorkspaceListCWProxy {
  const _$JoinableWorkspaceListCWProxyImpl(this._value);

  final JoinableWorkspaceList _value;

  @override
  JoinableWorkspaceList items(List<JoinableWorkspace> items) =>
      call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `JoinableWorkspaceList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// JoinableWorkspaceList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  JoinableWorkspaceList call({Object? items = const $CopyWithPlaceholder()}) {
    return JoinableWorkspaceList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<JoinableWorkspace>,
    );
  }
}

extension $JoinableWorkspaceListCopyWith on JoinableWorkspaceList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfJoinableWorkspaceList.copyWith(...)` or `instanceOfJoinableWorkspaceList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$JoinableWorkspaceListCWProxy get copyWith =>
      _$JoinableWorkspaceListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JoinableWorkspaceList _$JoinableWorkspaceListFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('JoinableWorkspaceList', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = JoinableWorkspaceList(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => JoinableWorkspace.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$JoinableWorkspaceListToJson(
  JoinableWorkspaceList instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

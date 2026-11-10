// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_badge.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WorkspaceBadgeCWProxy {
  WorkspaceBadge orgId(String orgId);

  WorkspaceBadge approvals(int approvals);

  WorkspaceBadge unread(int unread);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WorkspaceBadge(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WorkspaceBadge(...).copyWith(id: 12, name: "My name")
  /// ```
  WorkspaceBadge call({String orgId, int approvals, int unread});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWorkspaceBadge.copyWith(...)` or call `instanceOfWorkspaceBadge.copyWith.fieldName(value)` for a single field.
class _$WorkspaceBadgeCWProxyImpl implements _$WorkspaceBadgeCWProxy {
  const _$WorkspaceBadgeCWProxyImpl(this._value);

  final WorkspaceBadge _value;

  @override
  WorkspaceBadge orgId(String orgId) => call(orgId: orgId);

  @override
  WorkspaceBadge approvals(int approvals) => call(approvals: approvals);

  @override
  WorkspaceBadge unread(int unread) => call(unread: unread);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WorkspaceBadge(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WorkspaceBadge(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WorkspaceBadge call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? approvals = const $CopyWithPlaceholder(),
    Object? unread = const $CopyWithPlaceholder(),
  }) {
    return WorkspaceBadge(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      approvals: approvals == const $CopyWithPlaceholder() || approvals == null
          ? _value.approvals
          // ignore: cast_nullable_to_non_nullable
          : approvals as int,
      unread: unread == const $CopyWithPlaceholder() || unread == null
          ? _value.unread
          // ignore: cast_nullable_to_non_nullable
          : unread as int,
    );
  }
}

extension $WorkspaceBadgeCopyWith on WorkspaceBadge {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWorkspaceBadge.copyWith(...)` or `instanceOfWorkspaceBadge.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WorkspaceBadgeCWProxy get copyWith => _$WorkspaceBadgeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkspaceBadge _$WorkspaceBadgeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WorkspaceBadge', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['org_id', 'approvals', 'unread']);
      final val = WorkspaceBadge(
        orgId: $checkedConvert('org_id', (v) => v as String),
        approvals: $checkedConvert('approvals', (v) => (v as num).toInt()),
        unread: $checkedConvert('unread', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'orgId': 'org_id'});

Map<String, dynamic> _$WorkspaceBadgeToJson(WorkspaceBadge instance) =>
    <String, dynamic>{
      'org_id': instance.orgId,
      'approvals': instance.approvals,
      'unread': instance.unread,
    };

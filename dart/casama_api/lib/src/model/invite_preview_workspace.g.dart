// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_preview_workspace.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InvitePreviewWorkspaceCWProxy {
  InvitePreviewWorkspace name(String name);

  InvitePreviewWorkspace icon(String? icon);

  InvitePreviewWorkspace color(String? color);

  InvitePreviewWorkspace memberCount(int memberCount);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InvitePreviewWorkspace(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InvitePreviewWorkspace(...).copyWith(id: 12, name: "My name")
  /// ```
  InvitePreviewWorkspace call({
    String name,
    String? icon,
    String? color,
    int memberCount,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInvitePreviewWorkspace.copyWith(...)` or call `instanceOfInvitePreviewWorkspace.copyWith.fieldName(value)` for a single field.
class _$InvitePreviewWorkspaceCWProxyImpl
    implements _$InvitePreviewWorkspaceCWProxy {
  const _$InvitePreviewWorkspaceCWProxyImpl(this._value);

  final InvitePreviewWorkspace _value;

  @override
  InvitePreviewWorkspace name(String name) => call(name: name);

  @override
  InvitePreviewWorkspace icon(String? icon) => call(icon: icon);

  @override
  InvitePreviewWorkspace color(String? color) => call(color: color);

  @override
  InvitePreviewWorkspace memberCount(int memberCount) =>
      call(memberCount: memberCount);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InvitePreviewWorkspace(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InvitePreviewWorkspace(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  InvitePreviewWorkspace call({
    Object? name = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
    Object? memberCount = const $CopyWithPlaceholder(),
  }) {
    return InvitePreviewWorkspace(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      icon: icon == const $CopyWithPlaceholder()
          ? _value.icon
          // ignore: cast_nullable_to_non_nullable
          : icon as String?,
      color: color == const $CopyWithPlaceholder()
          ? _value.color
          // ignore: cast_nullable_to_non_nullable
          : color as String?,
      memberCount:
          memberCount == const $CopyWithPlaceholder() || memberCount == null
          ? _value.memberCount
          // ignore: cast_nullable_to_non_nullable
          : memberCount as int,
    );
  }
}

extension $InvitePreviewWorkspaceCopyWith on InvitePreviewWorkspace {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInvitePreviewWorkspace.copyWith(...)` or `instanceOfInvitePreviewWorkspace.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InvitePreviewWorkspaceCWProxy get copyWith =>
      _$InvitePreviewWorkspaceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvitePreviewWorkspace _$InvitePreviewWorkspaceFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('InvitePreviewWorkspace', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['name', 'icon', 'color', 'member_count'],
  );
  final val = InvitePreviewWorkspace(
    name: $checkedConvert('name', (v) => v as String),
    icon: $checkedConvert('icon', (v) => v as String?),
    color: $checkedConvert('color', (v) => v as String?),
    memberCount: $checkedConvert('member_count', (v) => (v as num).toInt()),
  );
  return val;
}, fieldKeyMap: const {'memberCount': 'member_count'});

Map<String, dynamic> _$InvitePreviewWorkspaceToJson(
  InvitePreviewWorkspace instance,
) => <String, dynamic>{
  'name': instance.name,
  'icon': instance.icon,
  'color': instance.color,
  'member_count': instance.memberCount,
};

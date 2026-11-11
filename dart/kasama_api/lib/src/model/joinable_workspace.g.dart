// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'joinable_workspace.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$JoinableWorkspaceCWProxy {
  JoinableWorkspace id(String id);

  JoinableWorkspace name(String name);

  JoinableWorkspace icon(String? icon);

  JoinableWorkspace color(String? color);

  JoinableWorkspace memberCount(int memberCount);

  JoinableWorkspace domain(String domain);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `JoinableWorkspace(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// JoinableWorkspace(...).copyWith(id: 12, name: "My name")
  /// ```
  JoinableWorkspace call({
    String id,
    String name,
    String? icon,
    String? color,
    int memberCount,
    String domain,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfJoinableWorkspace.copyWith(...)` or call `instanceOfJoinableWorkspace.copyWith.fieldName(value)` for a single field.
class _$JoinableWorkspaceCWProxyImpl implements _$JoinableWorkspaceCWProxy {
  const _$JoinableWorkspaceCWProxyImpl(this._value);

  final JoinableWorkspace _value;

  @override
  JoinableWorkspace id(String id) => call(id: id);

  @override
  JoinableWorkspace name(String name) => call(name: name);

  @override
  JoinableWorkspace icon(String? icon) => call(icon: icon);

  @override
  JoinableWorkspace color(String? color) => call(color: color);

  @override
  JoinableWorkspace memberCount(int memberCount) =>
      call(memberCount: memberCount);

  @override
  JoinableWorkspace domain(String domain) => call(domain: domain);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `JoinableWorkspace(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// JoinableWorkspace(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  JoinableWorkspace call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
    Object? memberCount = const $CopyWithPlaceholder(),
    Object? domain = const $CopyWithPlaceholder(),
  }) {
    return JoinableWorkspace(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
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
      domain: domain == const $CopyWithPlaceholder() || domain == null
          ? _value.domain
          // ignore: cast_nullable_to_non_nullable
          : domain as String,
    );
  }
}

extension $JoinableWorkspaceCopyWith on JoinableWorkspace {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfJoinableWorkspace.copyWith(...)` or `instanceOfJoinableWorkspace.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$JoinableWorkspaceCWProxy get copyWith =>
      _$JoinableWorkspaceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JoinableWorkspace _$JoinableWorkspaceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('JoinableWorkspace', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'name',
          'icon',
          'color',
          'member_count',
          'domain',
        ],
      );
      final val = JoinableWorkspace(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        icon: $checkedConvert('icon', (v) => v as String?),
        color: $checkedConvert('color', (v) => v as String?),
        memberCount: $checkedConvert('member_count', (v) => (v as num).toInt()),
        domain: $checkedConvert('domain', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'memberCount': 'member_count'});

Map<String, dynamic> _$JoinableWorkspaceToJson(JoinableWorkspace instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'member_count': instance.memberCount,
      'domain': instance.domain,
    };

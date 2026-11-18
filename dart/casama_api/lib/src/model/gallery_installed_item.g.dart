// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_installed_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryInstalledItemCWProxy {
  GalleryInstalledItem type(GalleryWorkspaceKind type);

  GalleryInstalledItem id(String id);

  GalleryInstalledItem name(String name);

  GalleryInstalledItem installedVersion(int installedVersion);

  GalleryInstalledItem latestVersion(int? latestVersion);

  GalleryInstalledItem update(bool update);

  GalleryInstalledItem breaking(bool breaking);

  GalleryInstalledItem accessAdded(GalleryAccessDiff accessAdded);

  GalleryInstalledItem retired(bool retired);

  GalleryInstalledItem replacement(GalleryRef? replacement);

  GalleryInstalledItem changelog(List<GalleryChange> changelog);

  GalleryInstalledItem installedAt(DateTime installedAt);

  GalleryInstalledItem target(GalleryInstalledItemTarget target);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryInstalledItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryInstalledItem(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryInstalledItem call({
    GalleryWorkspaceKind type,
    String id,
    String name,
    int installedVersion,
    int? latestVersion,
    bool update,
    bool breaking,
    GalleryAccessDiff accessAdded,
    bool retired,
    GalleryRef? replacement,
    List<GalleryChange> changelog,
    DateTime installedAt,
    GalleryInstalledItemTarget target,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryInstalledItem.copyWith(...)` or call `instanceOfGalleryInstalledItem.copyWith.fieldName(value)` for a single field.
class _$GalleryInstalledItemCWProxyImpl
    implements _$GalleryInstalledItemCWProxy {
  const _$GalleryInstalledItemCWProxyImpl(this._value);

  final GalleryInstalledItem _value;

  @override
  GalleryInstalledItem type(GalleryWorkspaceKind type) => call(type: type);

  @override
  GalleryInstalledItem id(String id) => call(id: id);

  @override
  GalleryInstalledItem name(String name) => call(name: name);

  @override
  GalleryInstalledItem installedVersion(int installedVersion) =>
      call(installedVersion: installedVersion);

  @override
  GalleryInstalledItem latestVersion(int? latestVersion) =>
      call(latestVersion: latestVersion);

  @override
  GalleryInstalledItem update(bool update) => call(update: update);

  @override
  GalleryInstalledItem breaking(bool breaking) => call(breaking: breaking);

  @override
  GalleryInstalledItem accessAdded(GalleryAccessDiff accessAdded) =>
      call(accessAdded: accessAdded);

  @override
  GalleryInstalledItem retired(bool retired) => call(retired: retired);

  @override
  GalleryInstalledItem replacement(GalleryRef? replacement) =>
      call(replacement: replacement);

  @override
  GalleryInstalledItem changelog(List<GalleryChange> changelog) =>
      call(changelog: changelog);

  @override
  GalleryInstalledItem installedAt(DateTime installedAt) =>
      call(installedAt: installedAt);

  @override
  GalleryInstalledItem target(GalleryInstalledItemTarget target) =>
      call(target: target);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryInstalledItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryInstalledItem(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryInstalledItem call({
    Object? type = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? installedVersion = const $CopyWithPlaceholder(),
    Object? latestVersion = const $CopyWithPlaceholder(),
    Object? update = const $CopyWithPlaceholder(),
    Object? breaking = const $CopyWithPlaceholder(),
    Object? accessAdded = const $CopyWithPlaceholder(),
    Object? retired = const $CopyWithPlaceholder(),
    Object? replacement = const $CopyWithPlaceholder(),
    Object? changelog = const $CopyWithPlaceholder(),
    Object? installedAt = const $CopyWithPlaceholder(),
    Object? target = const $CopyWithPlaceholder(),
  }) {
    return GalleryInstalledItem(
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as GalleryWorkspaceKind,
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      installedVersion:
          installedVersion == const $CopyWithPlaceholder() ||
              installedVersion == null
          ? _value.installedVersion
          // ignore: cast_nullable_to_non_nullable
          : installedVersion as int,
      latestVersion: latestVersion == const $CopyWithPlaceholder()
          ? _value.latestVersion
          // ignore: cast_nullable_to_non_nullable
          : latestVersion as int?,
      update: update == const $CopyWithPlaceholder() || update == null
          ? _value.update
          // ignore: cast_nullable_to_non_nullable
          : update as bool,
      breaking: breaking == const $CopyWithPlaceholder() || breaking == null
          ? _value.breaking
          // ignore: cast_nullable_to_non_nullable
          : breaking as bool,
      accessAdded:
          accessAdded == const $CopyWithPlaceholder() || accessAdded == null
          ? _value.accessAdded
          // ignore: cast_nullable_to_non_nullable
          : accessAdded as GalleryAccessDiff,
      retired: retired == const $CopyWithPlaceholder() || retired == null
          ? _value.retired
          // ignore: cast_nullable_to_non_nullable
          : retired as bool,
      replacement: replacement == const $CopyWithPlaceholder()
          ? _value.replacement
          // ignore: cast_nullable_to_non_nullable
          : replacement as GalleryRef?,
      changelog: changelog == const $CopyWithPlaceholder() || changelog == null
          ? _value.changelog
          // ignore: cast_nullable_to_non_nullable
          : changelog as List<GalleryChange>,
      installedAt:
          installedAt == const $CopyWithPlaceholder() || installedAt == null
          ? _value.installedAt
          // ignore: cast_nullable_to_non_nullable
          : installedAt as DateTime,
      target: target == const $CopyWithPlaceholder() || target == null
          ? _value.target
          // ignore: cast_nullable_to_non_nullable
          : target as GalleryInstalledItemTarget,
    );
  }
}

extension $GalleryInstalledItemCopyWith on GalleryInstalledItem {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryInstalledItem.copyWith(...)` or `instanceOfGalleryInstalledItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryInstalledItemCWProxy get copyWith =>
      _$GalleryInstalledItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryInstalledItem _$GalleryInstalledItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'GalleryInstalledItem',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'type',
        'id',
        'name',
        'installed_version',
        'latest_version',
        'update',
        'breaking',
        'access_added',
        'retired',
        'changelog',
        'installed_at',
        'target',
      ],
    );
    final val = GalleryInstalledItem(
      type: $checkedConvert(
        'type',
        (v) => $enumDecode(_$GalleryWorkspaceKindEnumMap, v),
      ),
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      installedVersion: $checkedConvert(
        'installed_version',
        (v) => (v as num).toInt(),
      ),
      latestVersion: $checkedConvert(
        'latest_version',
        (v) => (v as num?)?.toInt(),
      ),
      update: $checkedConvert('update', (v) => v as bool),
      breaking: $checkedConvert('breaking', (v) => v as bool),
      accessAdded: $checkedConvert(
        'access_added',
        (v) => GalleryAccessDiff.fromJson(v as Map<String, dynamic>),
      ),
      retired: $checkedConvert('retired', (v) => v as bool),
      replacement: $checkedConvert(
        'replacement',
        (v) =>
            v == null ? null : GalleryRef.fromJson(v as Map<String, dynamic>),
      ),
      changelog: $checkedConvert(
        'changelog',
        (v) => (v as List<dynamic>)
            .map((e) => GalleryChange.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      installedAt: $checkedConvert(
        'installed_at',
        (v) => DateTime.parse(v as String),
      ),
      target: $checkedConvert(
        'target',
        (v) => GalleryInstalledItemTarget.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'installedVersion': 'installed_version',
    'latestVersion': 'latest_version',
    'accessAdded': 'access_added',
    'installedAt': 'installed_at',
  },
);

Map<String, dynamic> _$GalleryInstalledItemToJson(
  GalleryInstalledItem instance,
) => <String, dynamic>{
  'type': _$GalleryWorkspaceKindEnumMap[instance.type]!,
  'id': instance.id,
  'name': instance.name,
  'installed_version': instance.installedVersion,
  'latest_version': instance.latestVersion,
  'update': instance.update,
  'breaking': instance.breaking,
  'access_added': instance.accessAdded.toJson(),
  'retired': instance.retired,
  'replacement': ?instance.replacement?.toJson(),
  'changelog': instance.changelog.map((e) => e.toJson()).toList(),
  'installed_at': instance.installedAt.toIso8601String(),
  'target': instance.target.toJson(),
};

const _$GalleryWorkspaceKindEnumMap = {
  GalleryWorkspaceKind.skill: 'skill',
  GalleryWorkspaceKind.app: 'app',
  GalleryWorkspaceKind.bot: 'bot',
  GalleryWorkspaceKind.routine: 'routine',
  GalleryWorkspaceKind.plugin: 'plugin',
};

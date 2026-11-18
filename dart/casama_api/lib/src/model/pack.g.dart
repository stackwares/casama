// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackCWProxy {
  Pack id(String id);

  Pack orgId(String orgId);

  Pack name(String name);

  Pack title(String title);

  Pack version(String? version);

  Pack description(String description);

  Pack summary(String summary);

  Pack icon(String icon);

  Pack source_(PackSource source_);

  Pack commit(String? commit);

  Pack reviewed(bool reviewed);

  Pack items(List<PackItem> items);

  Pack installedAt(DateTime installedAt);

  Pack updatedAt(DateTime updatedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Pack(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Pack(...).copyWith(id: 12, name: "My name")
  /// ```
  Pack call({
    String id,
    String orgId,
    String name,
    String title,
    String? version,
    String description,
    String summary,
    String icon,
    PackSource source_,
    String? commit,
    bool reviewed,
    List<PackItem> items,
    DateTime installedAt,
    DateTime updatedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPack.copyWith(...)` or call `instanceOfPack.copyWith.fieldName(value)` for a single field.
class _$PackCWProxyImpl implements _$PackCWProxy {
  const _$PackCWProxyImpl(this._value);

  final Pack _value;

  @override
  Pack id(String id) => call(id: id);

  @override
  Pack orgId(String orgId) => call(orgId: orgId);

  @override
  Pack name(String name) => call(name: name);

  @override
  Pack title(String title) => call(title: title);

  @override
  Pack version(String? version) => call(version: version);

  @override
  Pack description(String description) => call(description: description);

  @override
  Pack summary(String summary) => call(summary: summary);

  @override
  Pack icon(String icon) => call(icon: icon);

  @override
  Pack source_(PackSource source_) => call(source_: source_);

  @override
  Pack commit(String? commit) => call(commit: commit);

  @override
  Pack reviewed(bool reviewed) => call(reviewed: reviewed);

  @override
  Pack items(List<PackItem> items) => call(items: items);

  @override
  Pack installedAt(DateTime installedAt) => call(installedAt: installedAt);

  @override
  Pack updatedAt(DateTime updatedAt) => call(updatedAt: updatedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Pack(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Pack(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Pack call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? summary = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? commit = const $CopyWithPlaceholder(),
    Object? reviewed = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? installedAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
  }) {
    return Pack(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as String?,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      summary: summary == const $CopyWithPlaceholder() || summary == null
          ? _value.summary
          // ignore: cast_nullable_to_non_nullable
          : summary as String,
      icon: icon == const $CopyWithPlaceholder() || icon == null
          ? _value.icon
          // ignore: cast_nullable_to_non_nullable
          : icon as String,
      source_: source_ == const $CopyWithPlaceholder() || source_ == null
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as PackSource,
      commit: commit == const $CopyWithPlaceholder()
          ? _value.commit
          // ignore: cast_nullable_to_non_nullable
          : commit as String?,
      reviewed: reviewed == const $CopyWithPlaceholder() || reviewed == null
          ? _value.reviewed
          // ignore: cast_nullable_to_non_nullable
          : reviewed as bool,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<PackItem>,
      installedAt:
          installedAt == const $CopyWithPlaceholder() || installedAt == null
          ? _value.installedAt
          // ignore: cast_nullable_to_non_nullable
          : installedAt as DateTime,
      updatedAt: updatedAt == const $CopyWithPlaceholder() || updatedAt == null
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
    );
  }
}

extension $PackCopyWith on Pack {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPack.copyWith(...)` or `instanceOfPack.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackCWProxy get copyWith => _$PackCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Pack _$PackFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Pack',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'org_id',
        'name',
        'title',
        'version',
        'description',
        'summary',
        'icon',
        'source',
        'commit',
        'reviewed',
        'items',
        'installed_at',
        'updated_at',
      ],
    );
    final val = Pack(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      version: $checkedConvert('version', (v) => v as String?),
      description: $checkedConvert('description', (v) => v as String),
      summary: $checkedConvert('summary', (v) => v as String),
      icon: $checkedConvert('icon', (v) => v as String),
      source_: $checkedConvert(
        'source',
        (v) => PackSource.fromJson(v as Map<String, dynamic>),
      ),
      commit: $checkedConvert('commit', (v) => v as String?),
      reviewed: $checkedConvert('reviewed', (v) => v as bool),
      items: $checkedConvert(
        'items',
        (v) => (v as List<dynamic>)
            .map((e) => PackItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      installedAt: $checkedConvert(
        'installed_at',
        (v) => DateTime.parse(v as String),
      ),
      updatedAt: $checkedConvert(
        'updated_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'source_': 'source',
    'installedAt': 'installed_at',
    'updatedAt': 'updated_at',
  },
);

Map<String, dynamic> _$PackToJson(Pack instance) => <String, dynamic>{
  'id': instance.id,
  'org_id': instance.orgId,
  'name': instance.name,
  'title': instance.title,
  'version': instance.version,
  'description': instance.description,
  'summary': instance.summary,
  'icon': instance.icon,
  'source': instance.source_.toJson(),
  'commit': instance.commit,
  'reviewed': instance.reviewed,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'installed_at': instance.installedAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'directory_plugin.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DirectoryPluginCWProxy {
  DirectoryPlugin id(String id);

  DirectoryPlugin name(String name);

  DirectoryPlugin description(String description);

  DirectoryPlugin url(String url);

  DirectoryPlugin commit(String commit);

  DirectoryPlugin icon(String? icon);

  DirectoryPlugin adds(List<String> adds);

  DirectoryPlugin author(ContentAuthor author);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DirectoryPlugin(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DirectoryPlugin(...).copyWith(id: 12, name: "My name")
  /// ```
  DirectoryPlugin call({
    String id,
    String name,
    String description,
    String url,
    String commit,
    String? icon,
    List<String> adds,
    ContentAuthor author,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDirectoryPlugin.copyWith(...)` or call `instanceOfDirectoryPlugin.copyWith.fieldName(value)` for a single field.
class _$DirectoryPluginCWProxyImpl implements _$DirectoryPluginCWProxy {
  const _$DirectoryPluginCWProxyImpl(this._value);

  final DirectoryPlugin _value;

  @override
  DirectoryPlugin id(String id) => call(id: id);

  @override
  DirectoryPlugin name(String name) => call(name: name);

  @override
  DirectoryPlugin description(String description) =>
      call(description: description);

  @override
  DirectoryPlugin url(String url) => call(url: url);

  @override
  DirectoryPlugin commit(String commit) => call(commit: commit);

  @override
  DirectoryPlugin icon(String? icon) => call(icon: icon);

  @override
  DirectoryPlugin adds(List<String> adds) => call(adds: adds);

  @override
  DirectoryPlugin author(ContentAuthor author) => call(author: author);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DirectoryPlugin(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DirectoryPlugin(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DirectoryPlugin call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? commit = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? adds = const $CopyWithPlaceholder(),
    Object? author = const $CopyWithPlaceholder(),
  }) {
    return DirectoryPlugin(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      commit: commit == const $CopyWithPlaceholder() || commit == null
          ? _value.commit
          // ignore: cast_nullable_to_non_nullable
          : commit as String,
      icon: icon == const $CopyWithPlaceholder()
          ? _value.icon
          // ignore: cast_nullable_to_non_nullable
          : icon as String?,
      adds: adds == const $CopyWithPlaceholder() || adds == null
          ? _value.adds
          // ignore: cast_nullable_to_non_nullable
          : adds as List<String>,
      author: author == const $CopyWithPlaceholder() || author == null
          ? _value.author
          // ignore: cast_nullable_to_non_nullable
          : author as ContentAuthor,
    );
  }
}

extension $DirectoryPluginCopyWith on DirectoryPlugin {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDirectoryPlugin.copyWith(...)` or `instanceOfDirectoryPlugin.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DirectoryPluginCWProxy get copyWith => _$DirectoryPluginCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DirectoryPlugin _$DirectoryPluginFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DirectoryPlugin', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'name',
          'description',
          'url',
          'commit',
          'adds',
          'author',
        ],
      );
      final val = DirectoryPlugin(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String),
        url: $checkedConvert('url', (v) => v as String),
        commit: $checkedConvert('commit', (v) => v as String),
        icon: $checkedConvert('icon', (v) => v as String?),
        adds: $checkedConvert(
          'adds',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        author: $checkedConvert(
          'author',
          (v) => ContentAuthor.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DirectoryPluginToJson(DirectoryPlugin instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'url': instance.url,
      'commit': instance.commit,
      'icon': ?instance.icon,
      'adds': instance.adds,
      'author': instance.author.toJson(),
    };

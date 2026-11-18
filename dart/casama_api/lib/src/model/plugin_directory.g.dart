// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_directory.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PluginDirectoryCWProxy {
  PluginDirectory items(List<DirectoryPlugin> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginDirectory(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginDirectory(...).copyWith(id: 12, name: "My name")
  /// ```
  PluginDirectory call({List<DirectoryPlugin> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPluginDirectory.copyWith(...)` or call `instanceOfPluginDirectory.copyWith.fieldName(value)` for a single field.
class _$PluginDirectoryCWProxyImpl implements _$PluginDirectoryCWProxy {
  const _$PluginDirectoryCWProxyImpl(this._value);

  final PluginDirectory _value;

  @override
  PluginDirectory items(List<DirectoryPlugin> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginDirectory(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginDirectory(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PluginDirectory call({Object? items = const $CopyWithPlaceholder()}) {
    return PluginDirectory(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<DirectoryPlugin>,
    );
  }
}

extension $PluginDirectoryCopyWith on PluginDirectory {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPluginDirectory.copyWith(...)` or `instanceOfPluginDirectory.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PluginDirectoryCWProxy get copyWith => _$PluginDirectoryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PluginDirectory _$PluginDirectoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PluginDirectory', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = PluginDirectory(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => DirectoryPlugin.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PluginDirectoryToJson(PluginDirectory instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

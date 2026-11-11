// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PluginListCWProxy {
  PluginList items(List<Plugin> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginList(...).copyWith(id: 12, name: "My name")
  /// ```
  PluginList call({List<Plugin> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPluginList.copyWith(...)` or call `instanceOfPluginList.copyWith.fieldName(value)` for a single field.
class _$PluginListCWProxyImpl implements _$PluginListCWProxy {
  const _$PluginListCWProxyImpl(this._value);

  final PluginList _value;

  @override
  PluginList items(List<Plugin> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PluginList call({Object? items = const $CopyWithPlaceholder()}) {
    return PluginList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Plugin>,
    );
  }
}

extension $PluginListCopyWith on PluginList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPluginList.copyWith(...)` or `instanceOfPluginList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PluginListCWProxy get copyWith => _$PluginListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PluginList _$PluginListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PluginList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = PluginList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Plugin.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PluginListToJson(PluginList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

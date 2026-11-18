// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_app_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProviderAppListCWProxy {
  ProviderAppList items(List<ProviderApp> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderAppList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderAppList(...).copyWith(id: 12, name: "My name")
  /// ```
  ProviderAppList call({List<ProviderApp> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProviderAppList.copyWith(...)` or call `instanceOfProviderAppList.copyWith.fieldName(value)` for a single field.
class _$ProviderAppListCWProxyImpl implements _$ProviderAppListCWProxy {
  const _$ProviderAppListCWProxyImpl(this._value);

  final ProviderAppList _value;

  @override
  ProviderAppList items(List<ProviderApp> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderAppList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderAppList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProviderAppList call({Object? items = const $CopyWithPlaceholder()}) {
    return ProviderAppList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<ProviderApp>,
    );
  }
}

extension $ProviderAppListCopyWith on ProviderAppList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProviderAppList.copyWith(...)` or `instanceOfProviderAppList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProviderAppListCWProxy get copyWith => _$ProviderAppListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProviderAppList _$ProviderAppListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProviderAppList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ProviderAppList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => ProviderApp.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ProviderAppListToJson(ProviderAppList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

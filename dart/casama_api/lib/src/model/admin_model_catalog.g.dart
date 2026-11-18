// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_model_catalog.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminModelCatalogCWProxy {
  AdminModelCatalog catalog(Map<String, Object?> catalog);

  AdminModelCatalog builtIn(Map<String, Object?> builtIn);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminModelCatalog(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminModelCatalog(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminModelCatalog call({
    Map<String, Object?> catalog,
    Map<String, Object?> builtIn,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminModelCatalog.copyWith(...)` or call `instanceOfAdminModelCatalog.copyWith.fieldName(value)` for a single field.
class _$AdminModelCatalogCWProxyImpl implements _$AdminModelCatalogCWProxy {
  const _$AdminModelCatalogCWProxyImpl(this._value);

  final AdminModelCatalog _value;

  @override
  AdminModelCatalog catalog(Map<String, Object?> catalog) =>
      call(catalog: catalog);

  @override
  AdminModelCatalog builtIn(Map<String, Object?> builtIn) =>
      call(builtIn: builtIn);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminModelCatalog(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminModelCatalog(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminModelCatalog call({
    Object? catalog = const $CopyWithPlaceholder(),
    Object? builtIn = const $CopyWithPlaceholder(),
  }) {
    return AdminModelCatalog(
      catalog: catalog == const $CopyWithPlaceholder() || catalog == null
          ? _value.catalog
          // ignore: cast_nullable_to_non_nullable
          : catalog as Map<String, Object?>,
      builtIn: builtIn == const $CopyWithPlaceholder() || builtIn == null
          ? _value.builtIn
          // ignore: cast_nullable_to_non_nullable
          : builtIn as Map<String, Object?>,
    );
  }
}

extension $AdminModelCatalogCopyWith on AdminModelCatalog {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminModelCatalog.copyWith(...)` or `instanceOfAdminModelCatalog.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminModelCatalogCWProxy get copyWith =>
      _$AdminModelCatalogCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminModelCatalog _$AdminModelCatalogFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminModelCatalog', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['catalog', 'built_in']);
      final val = AdminModelCatalog(
        catalog: $checkedConvert('catalog', (v) => v as Map<String, dynamic>),
        builtIn: $checkedConvert('built_in', (v) => v as Map<String, dynamic>),
      );
      return val;
    }, fieldKeyMap: const {'builtIn': 'built_in'});

Map<String, dynamic> _$AdminModelCatalogToJson(AdminModelCatalog instance) =>
    <String, dynamic>{
      'catalog': instance.catalog,
      'built_in': instance.builtIn,
    };

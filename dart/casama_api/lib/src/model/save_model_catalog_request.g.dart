// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_model_catalog_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SaveModelCatalogRequestCWProxy {
  SaveModelCatalogRequest catalog(Map<String, Object?> catalog);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveModelCatalogRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveModelCatalogRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SaveModelCatalogRequest call({Map<String, Object?> catalog});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSaveModelCatalogRequest.copyWith(...)` or call `instanceOfSaveModelCatalogRequest.copyWith.fieldName(value)` for a single field.
class _$SaveModelCatalogRequestCWProxyImpl
    implements _$SaveModelCatalogRequestCWProxy {
  const _$SaveModelCatalogRequestCWProxyImpl(this._value);

  final SaveModelCatalogRequest _value;

  @override
  SaveModelCatalogRequest catalog(Map<String, Object?> catalog) =>
      call(catalog: catalog);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveModelCatalogRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveModelCatalogRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SaveModelCatalogRequest call({
    Object? catalog = const $CopyWithPlaceholder(),
  }) {
    return SaveModelCatalogRequest(
      catalog: catalog == const $CopyWithPlaceholder() || catalog == null
          ? _value.catalog
          // ignore: cast_nullable_to_non_nullable
          : catalog as Map<String, Object?>,
    );
  }
}

extension $SaveModelCatalogRequestCopyWith on SaveModelCatalogRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSaveModelCatalogRequest.copyWith(...)` or `instanceOfSaveModelCatalogRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SaveModelCatalogRequestCWProxy get copyWith =>
      _$SaveModelCatalogRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveModelCatalogRequest _$SaveModelCatalogRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SaveModelCatalogRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['catalog']);
  final val = SaveModelCatalogRequest(
    catalog: $checkedConvert('catalog', (v) => v as Map<String, dynamic>),
  );
  return val;
});

Map<String, dynamic> _$SaveModelCatalogRequestToJson(
  SaveModelCatalogRequest instance,
) => <String, dynamic>{'catalog': instance.catalog};

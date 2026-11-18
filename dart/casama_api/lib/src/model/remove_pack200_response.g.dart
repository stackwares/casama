// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remove_pack200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RemovePack200ResponseCWProxy {
  RemovePack200Response deleted(String deleted);

  RemovePack200Response kept(int kept);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RemovePack200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RemovePack200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  RemovePack200Response call({String deleted, int kept});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRemovePack200Response.copyWith(...)` or call `instanceOfRemovePack200Response.copyWith.fieldName(value)` for a single field.
class _$RemovePack200ResponseCWProxyImpl
    implements _$RemovePack200ResponseCWProxy {
  const _$RemovePack200ResponseCWProxyImpl(this._value);

  final RemovePack200Response _value;

  @override
  RemovePack200Response deleted(String deleted) => call(deleted: deleted);

  @override
  RemovePack200Response kept(int kept) => call(kept: kept);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RemovePack200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RemovePack200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RemovePack200Response call({
    Object? deleted = const $CopyWithPlaceholder(),
    Object? kept = const $CopyWithPlaceholder(),
  }) {
    return RemovePack200Response(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
      kept: kept == const $CopyWithPlaceholder() || kept == null
          ? _value.kept
          // ignore: cast_nullable_to_non_nullable
          : kept as int,
    );
  }
}

extension $RemovePack200ResponseCopyWith on RemovePack200Response {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRemovePack200Response.copyWith(...)` or `instanceOfRemovePack200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RemovePack200ResponseCWProxy get copyWith =>
      _$RemovePack200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RemovePack200Response _$RemovePack200ResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RemovePack200Response', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['deleted', 'kept']);
  final val = RemovePack200Response(
    deleted: $checkedConvert('deleted', (v) => v as String),
    kept: $checkedConvert('kept', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$RemovePack200ResponseToJson(
  RemovePack200Response instance,
) => <String, dynamic>{'deleted': instance.deleted, 'kept': instance.kept};

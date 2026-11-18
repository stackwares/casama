// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_look_preview.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackLookPreviewCWProxy {
  PackLookPreview type(PackLookPreviewTypeEnum type);

  PackLookPreview id(String id);

  PackLookPreview name(String name);

  PackLookPreview document(Map<String, Object?> document);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackLookPreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackLookPreview(...).copyWith(id: 12, name: "My name")
  /// ```
  PackLookPreview call({
    PackLookPreviewTypeEnum type,
    String id,
    String name,
    Map<String, Object?> document,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackLookPreview.copyWith(...)` or call `instanceOfPackLookPreview.copyWith.fieldName(value)` for a single field.
class _$PackLookPreviewCWProxyImpl implements _$PackLookPreviewCWProxy {
  const _$PackLookPreviewCWProxyImpl(this._value);

  final PackLookPreview _value;

  @override
  PackLookPreview type(PackLookPreviewTypeEnum type) => call(type: type);

  @override
  PackLookPreview id(String id) => call(id: id);

  @override
  PackLookPreview name(String name) => call(name: name);

  @override
  PackLookPreview document(Map<String, Object?> document) =>
      call(document: document);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackLookPreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackLookPreview(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackLookPreview call({
    Object? type = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? document = const $CopyWithPlaceholder(),
  }) {
    return PackLookPreview(
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as PackLookPreviewTypeEnum,
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      document: document == const $CopyWithPlaceholder() || document == null
          ? _value.document
          // ignore: cast_nullable_to_non_nullable
          : document as Map<String, Object?>,
    );
  }
}

extension $PackLookPreviewCopyWith on PackLookPreview {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackLookPreview.copyWith(...)` or `instanceOfPackLookPreview.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackLookPreviewCWProxy get copyWith => _$PackLookPreviewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackLookPreview _$PackLookPreviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PackLookPreview', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['type', 'id', 'name', 'document']);
      final val = PackLookPreview(
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$PackLookPreviewTypeEnumEnumMap, v),
        ),
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        document: $checkedConvert('document', (v) => v as Map<String, dynamic>),
      );
      return val;
    });

Map<String, dynamic> _$PackLookPreviewToJson(PackLookPreview instance) =>
    <String, dynamic>{
      'type': _$PackLookPreviewTypeEnumEnumMap[instance.type]!,
      'id': instance.id,
      'name': instance.name,
      'document': instance.document,
    };

const _$PackLookPreviewTypeEnumEnumMap = {
  PackLookPreviewTypeEnum.theme: 'theme',
  PackLookPreviewTypeEnum.scheme: 'scheme',
  PackLookPreviewTypeEnum.wallpaper: 'wallpaper',
};

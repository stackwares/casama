// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_pack_request_look.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ExportPackRequestLookCWProxy {
  ExportPackRequestLook type(ExportPackRequestLookTypeEnum type);

  ExportPackRequestLook name(String name);

  ExportPackRequestLook document(Map<String, Object?> document);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ExportPackRequestLook(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ExportPackRequestLook(...).copyWith(id: 12, name: "My name")
  /// ```
  ExportPackRequestLook call({
    ExportPackRequestLookTypeEnum type,
    String name,
    Map<String, Object?> document,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfExportPackRequestLook.copyWith(...)` or call `instanceOfExportPackRequestLook.copyWith.fieldName(value)` for a single field.
class _$ExportPackRequestLookCWProxyImpl
    implements _$ExportPackRequestLookCWProxy {
  const _$ExportPackRequestLookCWProxyImpl(this._value);

  final ExportPackRequestLook _value;

  @override
  ExportPackRequestLook type(ExportPackRequestLookTypeEnum type) =>
      call(type: type);

  @override
  ExportPackRequestLook name(String name) => call(name: name);

  @override
  ExportPackRequestLook document(Map<String, Object?> document) =>
      call(document: document);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ExportPackRequestLook(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ExportPackRequestLook(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ExportPackRequestLook call({
    Object? type = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? document = const $CopyWithPlaceholder(),
  }) {
    return ExportPackRequestLook(
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as ExportPackRequestLookTypeEnum,
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

extension $ExportPackRequestLookCopyWith on ExportPackRequestLook {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfExportPackRequestLook.copyWith(...)` or `instanceOfExportPackRequestLook.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ExportPackRequestLookCWProxy get copyWith =>
      _$ExportPackRequestLookCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExportPackRequestLook _$ExportPackRequestLookFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ExportPackRequestLook', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['type', 'name', 'document']);
  final val = ExportPackRequestLook(
    type: $checkedConvert(
      'type',
      (v) => $enumDecode(_$ExportPackRequestLookTypeEnumEnumMap, v),
    ),
    name: $checkedConvert('name', (v) => v as String),
    document: $checkedConvert('document', (v) => v as Map<String, dynamic>),
  );
  return val;
});

Map<String, dynamic> _$ExportPackRequestLookToJson(
  ExportPackRequestLook instance,
) => <String, dynamic>{
  'type': _$ExportPackRequestLookTypeEnumEnumMap[instance.type]!,
  'name': instance.name,
  'document': instance.document,
};

const _$ExportPackRequestLookTypeEnumEnumMap = {
  ExportPackRequestLookTypeEnum.theme: 'theme',
  ExportPackRequestLookTypeEnum.scheme: 'scheme',
  ExportPackRequestLookTypeEnum.wallpaper: 'wallpaper',
};

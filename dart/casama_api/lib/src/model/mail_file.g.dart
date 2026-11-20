// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mail_file.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MailFileCWProxy {
  MailFile index(int index);

  MailFile name(String name);

  MailFile mime(String mime);

  MailFile size(int size);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MailFile(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MailFile(...).copyWith(id: 12, name: "My name")
  /// ```
  MailFile call({int index, String name, String mime, int size});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMailFile.copyWith(...)` or call `instanceOfMailFile.copyWith.fieldName(value)` for a single field.
class _$MailFileCWProxyImpl implements _$MailFileCWProxy {
  const _$MailFileCWProxyImpl(this._value);

  final MailFile _value;

  @override
  MailFile index(int index) => call(index: index);

  @override
  MailFile name(String name) => call(name: name);

  @override
  MailFile mime(String mime) => call(mime: mime);

  @override
  MailFile size(int size) => call(size: size);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MailFile(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MailFile(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MailFile call({
    Object? index = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? mime = const $CopyWithPlaceholder(),
    Object? size = const $CopyWithPlaceholder(),
  }) {
    return MailFile(
      index: index == const $CopyWithPlaceholder() || index == null
          ? _value.index
          // ignore: cast_nullable_to_non_nullable
          : index as int,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      mime: mime == const $CopyWithPlaceholder() || mime == null
          ? _value.mime
          // ignore: cast_nullable_to_non_nullable
          : mime as String,
      size: size == const $CopyWithPlaceholder() || size == null
          ? _value.size
          // ignore: cast_nullable_to_non_nullable
          : size as int,
    );
  }
}

extension $MailFileCopyWith on MailFile {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMailFile.copyWith(...)` or `instanceOfMailFile.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MailFileCWProxy get copyWith => _$MailFileCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MailFile _$MailFileFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MailFile', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['index', 'name', 'mime', 'size']);
      final val = MailFile(
        index: $checkedConvert('index', (v) => (v as num).toInt()),
        name: $checkedConvert('name', (v) => v as String),
        mime: $checkedConvert('mime', (v) => v as String),
        size: $checkedConvert('size', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$MailFileToJson(MailFile instance) => <String, dynamic>{
  'index': instance.index,
  'name': instance.name,
  'mime': instance.mime,
  'size': instance.size,
};

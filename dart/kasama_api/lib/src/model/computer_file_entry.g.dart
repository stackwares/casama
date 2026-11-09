// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_file_entry.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerFileEntryCWProxy {
  ComputerFileEntry name(String name);

  ComputerFileEntry path(String path);

  ComputerFileEntry type(ComputerFileEntryTypeEnum type);

  ComputerFileEntry size(int size);

  ComputerFileEntry modified(String modified);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerFileEntry(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerFileEntry(...).copyWith(id: 12, name: "My name")
  /// ```
  ComputerFileEntry call({
    String name,
    String path,
    ComputerFileEntryTypeEnum type,
    int size,
    String modified,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComputerFileEntry.copyWith(...)` or call `instanceOfComputerFileEntry.copyWith.fieldName(value)` for a single field.
class _$ComputerFileEntryCWProxyImpl implements _$ComputerFileEntryCWProxy {
  const _$ComputerFileEntryCWProxyImpl(this._value);

  final ComputerFileEntry _value;

  @override
  ComputerFileEntry name(String name) => call(name: name);

  @override
  ComputerFileEntry path(String path) => call(path: path);

  @override
  ComputerFileEntry type(ComputerFileEntryTypeEnum type) => call(type: type);

  @override
  ComputerFileEntry size(int size) => call(size: size);

  @override
  ComputerFileEntry modified(String modified) => call(modified: modified);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerFileEntry(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerFileEntry(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComputerFileEntry call({
    Object? name = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? size = const $CopyWithPlaceholder(),
    Object? modified = const $CopyWithPlaceholder(),
  }) {
    return ComputerFileEntry(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      path: path == const $CopyWithPlaceholder() || path == null
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as ComputerFileEntryTypeEnum,
      size: size == const $CopyWithPlaceholder() || size == null
          ? _value.size
          // ignore: cast_nullable_to_non_nullable
          : size as int,
      modified: modified == const $CopyWithPlaceholder() || modified == null
          ? _value.modified
          // ignore: cast_nullable_to_non_nullable
          : modified as String,
    );
  }
}

extension $ComputerFileEntryCopyWith on ComputerFileEntry {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComputerFileEntry.copyWith(...)` or `instanceOfComputerFileEntry.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComputerFileEntryCWProxy get copyWith =>
      _$ComputerFileEntryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComputerFileEntry _$ComputerFileEntryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ComputerFileEntry', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['name', 'path', 'type', 'size', 'modified'],
      );
      final val = ComputerFileEntry(
        name: $checkedConvert('name', (v) => v as String),
        path: $checkedConvert('path', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$ComputerFileEntryTypeEnumEnumMap, v),
        ),
        size: $checkedConvert('size', (v) => (v as num).toInt()),
        modified: $checkedConvert('modified', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ComputerFileEntryToJson(ComputerFileEntry instance) =>
    <String, dynamic>{
      'name': instance.name,
      'path': instance.path,
      'type': _$ComputerFileEntryTypeEnumEnumMap[instance.type]!,
      'size': instance.size,
      'modified': instance.modified,
    };

const _$ComputerFileEntryTypeEnumEnumMap = {
  ComputerFileEntryTypeEnum.file: 'file',
  ComputerFileEntryTypeEnum.dir: 'dir',
  ComputerFileEntryTypeEnum.link: 'link',
};

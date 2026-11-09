// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_file_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerFileListCWProxy {
  ComputerFileList path(String path);

  ComputerFileList entries(List<ComputerFileEntry> entries);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerFileList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerFileList(...).copyWith(id: 12, name: "My name")
  /// ```
  ComputerFileList call({String path, List<ComputerFileEntry> entries});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComputerFileList.copyWith(...)` or call `instanceOfComputerFileList.copyWith.fieldName(value)` for a single field.
class _$ComputerFileListCWProxyImpl implements _$ComputerFileListCWProxy {
  const _$ComputerFileListCWProxyImpl(this._value);

  final ComputerFileList _value;

  @override
  ComputerFileList path(String path) => call(path: path);

  @override
  ComputerFileList entries(List<ComputerFileEntry> entries) =>
      call(entries: entries);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerFileList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerFileList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComputerFileList call({
    Object? path = const $CopyWithPlaceholder(),
    Object? entries = const $CopyWithPlaceholder(),
  }) {
    return ComputerFileList(
      path: path == const $CopyWithPlaceholder() || path == null
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      entries: entries == const $CopyWithPlaceholder() || entries == null
          ? _value.entries
          // ignore: cast_nullable_to_non_nullable
          : entries as List<ComputerFileEntry>,
    );
  }
}

extension $ComputerFileListCopyWith on ComputerFileList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComputerFileList.copyWith(...)` or `instanceOfComputerFileList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComputerFileListCWProxy get copyWith => _$ComputerFileListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComputerFileList _$ComputerFileListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ComputerFileList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['path', 'entries']);
      final val = ComputerFileList(
        path: $checkedConvert('path', (v) => v as String),
        entries: $checkedConvert(
          'entries',
          (v) => (v as List<dynamic>)
              .map((e) => ComputerFileEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ComputerFileListToJson(ComputerFileList instance) =>
    <String, dynamic>{
      'path': instance.path,
      'entries': instance.entries.map((e) => e.toJson()).toList(),
    };

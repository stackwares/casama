// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_file_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerFileListCWProxy {
  ComputerFileList path(String path);

  ComputerFileList entries(List<ComputerFileEntry> entries);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComputerFileList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComputerFileList(...).copyWith(id: 12, name: "My name")
  /// ````
  ComputerFileList call({String path, List<ComputerFileEntry> entries});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfComputerFileList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfComputerFileList.copyWith.fieldName(...)`
class _$ComputerFileListCWProxyImpl implements _$ComputerFileListCWProxy {
  const _$ComputerFileListCWProxyImpl(this._value);

  final ComputerFileList _value;

  @override
  ComputerFileList path(String path) => this(path: path);

  @override
  ComputerFileList entries(List<ComputerFileEntry> entries) =>
      this(entries: entries);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComputerFileList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComputerFileList(...).copyWith(id: 12, name: "My name")
  /// ````
  ComputerFileList call({
    Object? path = const $CopyWithPlaceholder(),
    Object? entries = const $CopyWithPlaceholder(),
  }) {
    return ComputerFileList(
      path: path == const $CopyWithPlaceholder()
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      entries: entries == const $CopyWithPlaceholder()
          ? _value.entries
          // ignore: cast_nullable_to_non_nullable
          : entries as List<ComputerFileEntry>,
    );
  }
}

extension $ComputerFileListCopyWith on ComputerFileList {
  /// Returns a callable class that can be used as follows: `instanceOfComputerFileList.copyWith(...)` or like so:`instanceOfComputerFileList.copyWith.fieldName(...)`.
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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_search_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FileSearchResultCWProxy {
  FileSearchResult computerId(String computerId);

  FileSearchResult computerName(String computerName);

  FileSearchResult path(String path);

  FileSearchResult match(FileSearchResultMatchEnum match);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `FileSearchResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// FileSearchResult(...).copyWith(id: 12, name: "My name")
  /// ```
  FileSearchResult call({
    String computerId,
    String computerName,
    String path,
    FileSearchResultMatchEnum match,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfFileSearchResult.copyWith(...)` or call `instanceOfFileSearchResult.copyWith.fieldName(value)` for a single field.
class _$FileSearchResultCWProxyImpl implements _$FileSearchResultCWProxy {
  const _$FileSearchResultCWProxyImpl(this._value);

  final FileSearchResult _value;

  @override
  FileSearchResult computerId(String computerId) =>
      call(computerId: computerId);

  @override
  FileSearchResult computerName(String computerName) =>
      call(computerName: computerName);

  @override
  FileSearchResult path(String path) => call(path: path);

  @override
  FileSearchResult match(FileSearchResultMatchEnum match) => call(match: match);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `FileSearchResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// FileSearchResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  FileSearchResult call({
    Object? computerId = const $CopyWithPlaceholder(),
    Object? computerName = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
    Object? match = const $CopyWithPlaceholder(),
  }) {
    return FileSearchResult(
      computerId:
          computerId == const $CopyWithPlaceholder() || computerId == null
          ? _value.computerId
          // ignore: cast_nullable_to_non_nullable
          : computerId as String,
      computerName:
          computerName == const $CopyWithPlaceholder() || computerName == null
          ? _value.computerName
          // ignore: cast_nullable_to_non_nullable
          : computerName as String,
      path: path == const $CopyWithPlaceholder() || path == null
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      match: match == const $CopyWithPlaceholder() || match == null
          ? _value.match
          // ignore: cast_nullable_to_non_nullable
          : match as FileSearchResultMatchEnum,
    );
  }
}

extension $FileSearchResultCopyWith on FileSearchResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfFileSearchResult.copyWith(...)` or `instanceOfFileSearchResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FileSearchResultCWProxy get copyWith => _$FileSearchResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileSearchResult _$FileSearchResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'FileSearchResult',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['computer_id', 'computer_name', 'path', 'match'],
        );
        final val = FileSearchResult(
          computerId: $checkedConvert('computer_id', (v) => v as String),
          computerName: $checkedConvert('computer_name', (v) => v as String),
          path: $checkedConvert('path', (v) => v as String),
          match: $checkedConvert(
            'match',
            (v) => $enumDecode(_$FileSearchResultMatchEnumEnumMap, v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'computerId': 'computer_id',
        'computerName': 'computer_name',
      },
    );

Map<String, dynamic> _$FileSearchResultToJson(FileSearchResult instance) =>
    <String, dynamic>{
      'computer_id': instance.computerId,
      'computer_name': instance.computerName,
      'path': instance.path,
      'match': _$FileSearchResultMatchEnumEnumMap[instance.match]!,
    };

const _$FileSearchResultMatchEnumEnumMap = {
  FileSearchResultMatchEnum.name: 'name',
  FileSearchResultMatchEnum.content: 'content',
};

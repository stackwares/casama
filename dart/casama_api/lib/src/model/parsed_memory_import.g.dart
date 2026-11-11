// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parsed_memory_import.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ParsedMemoryImportCWProxy {
  ParsedMemoryImport memories(List<ImportedMemoryItem> memories);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ParsedMemoryImport(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ParsedMemoryImport(...).copyWith(id: 12, name: "My name")
  /// ```
  ParsedMemoryImport call({List<ImportedMemoryItem> memories});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfParsedMemoryImport.copyWith(...)` or call `instanceOfParsedMemoryImport.copyWith.fieldName(value)` for a single field.
class _$ParsedMemoryImportCWProxyImpl implements _$ParsedMemoryImportCWProxy {
  const _$ParsedMemoryImportCWProxyImpl(this._value);

  final ParsedMemoryImport _value;

  @override
  ParsedMemoryImport memories(List<ImportedMemoryItem> memories) =>
      call(memories: memories);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ParsedMemoryImport(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ParsedMemoryImport(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ParsedMemoryImport call({Object? memories = const $CopyWithPlaceholder()}) {
    return ParsedMemoryImport(
      memories: memories == const $CopyWithPlaceholder() || memories == null
          ? _value.memories
          // ignore: cast_nullable_to_non_nullable
          : memories as List<ImportedMemoryItem>,
    );
  }
}

extension $ParsedMemoryImportCopyWith on ParsedMemoryImport {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfParsedMemoryImport.copyWith(...)` or `instanceOfParsedMemoryImport.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ParsedMemoryImportCWProxy get copyWith =>
      _$ParsedMemoryImportCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParsedMemoryImport _$ParsedMemoryImportFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ParsedMemoryImport', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['memories']);
      final val = ParsedMemoryImport(
        memories: $checkedConvert(
          'memories',
          (v) => (v as List<dynamic>)
              .map(
                (e) => ImportedMemoryItem.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ParsedMemoryImportToJson(ParsedMemoryImport instance) =>
    <String, dynamic>{
      'memories': instance.memories.map((e) => e.toJson()).toList(),
    };

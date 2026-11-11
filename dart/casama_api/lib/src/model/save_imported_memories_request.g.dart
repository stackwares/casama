// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_imported_memories_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SaveImportedMemoriesRequestCWProxy {
  SaveImportedMemoriesRequest memories(List<ImportedMemoryItem> memories);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveImportedMemoriesRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveImportedMemoriesRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SaveImportedMemoriesRequest call({List<ImportedMemoryItem> memories});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSaveImportedMemoriesRequest.copyWith(...)` or call `instanceOfSaveImportedMemoriesRequest.copyWith.fieldName(value)` for a single field.
class _$SaveImportedMemoriesRequestCWProxyImpl
    implements _$SaveImportedMemoriesRequestCWProxy {
  const _$SaveImportedMemoriesRequestCWProxyImpl(this._value);

  final SaveImportedMemoriesRequest _value;

  @override
  SaveImportedMemoriesRequest memories(List<ImportedMemoryItem> memories) =>
      call(memories: memories);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveImportedMemoriesRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveImportedMemoriesRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SaveImportedMemoriesRequest call({
    Object? memories = const $CopyWithPlaceholder(),
  }) {
    return SaveImportedMemoriesRequest(
      memories: memories == const $CopyWithPlaceholder() || memories == null
          ? _value.memories
          // ignore: cast_nullable_to_non_nullable
          : memories as List<ImportedMemoryItem>,
    );
  }
}

extension $SaveImportedMemoriesRequestCopyWith on SaveImportedMemoriesRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSaveImportedMemoriesRequest.copyWith(...)` or `instanceOfSaveImportedMemoriesRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SaveImportedMemoriesRequestCWProxy get copyWith =>
      _$SaveImportedMemoriesRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveImportedMemoriesRequest _$SaveImportedMemoriesRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SaveImportedMemoriesRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['memories']);
  final val = SaveImportedMemoriesRequest(
    memories: $checkedConvert(
      'memories',
      (v) => (v as List<dynamic>)
          .map((e) => ImportedMemoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$SaveImportedMemoriesRequestToJson(
  SaveImportedMemoriesRequest instance,
) => <String, dynamic>{
  'memories': instance.memories.map((e) => e.toJson()).toList(),
};

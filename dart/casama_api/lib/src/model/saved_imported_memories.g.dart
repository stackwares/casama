// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_imported_memories.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SavedImportedMemoriesCWProxy {
  SavedImportedMemories saved(int saved);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SavedImportedMemories(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SavedImportedMemories(...).copyWith(id: 12, name: "My name")
  /// ```
  SavedImportedMemories call({int saved});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSavedImportedMemories.copyWith(...)` or call `instanceOfSavedImportedMemories.copyWith.fieldName(value)` for a single field.
class _$SavedImportedMemoriesCWProxyImpl
    implements _$SavedImportedMemoriesCWProxy {
  const _$SavedImportedMemoriesCWProxyImpl(this._value);

  final SavedImportedMemories _value;

  @override
  SavedImportedMemories saved(int saved) => call(saved: saved);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SavedImportedMemories(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SavedImportedMemories(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SavedImportedMemories call({Object? saved = const $CopyWithPlaceholder()}) {
    return SavedImportedMemories(
      saved: saved == const $CopyWithPlaceholder() || saved == null
          ? _value.saved
          // ignore: cast_nullable_to_non_nullable
          : saved as int,
    );
  }
}

extension $SavedImportedMemoriesCopyWith on SavedImportedMemories {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSavedImportedMemories.copyWith(...)` or `instanceOfSavedImportedMemories.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SavedImportedMemoriesCWProxy get copyWith =>
      _$SavedImportedMemoriesCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SavedImportedMemories _$SavedImportedMemoriesFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SavedImportedMemories', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['saved']);
  final val = SavedImportedMemories(
    saved: $checkedConvert('saved', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$SavedImportedMemoriesToJson(
  SavedImportedMemories instance,
) => <String, dynamic>{'saved': instance.saved};

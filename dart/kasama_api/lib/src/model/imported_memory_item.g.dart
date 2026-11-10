// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'imported_memory_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ImportedMemoryItemCWProxy {
  ImportedMemoryItem kind(ImportedMemoryItemKindEnum kind);

  ImportedMemoryItem content(String content);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ImportedMemoryItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ImportedMemoryItem(...).copyWith(id: 12, name: "My name")
  /// ```
  ImportedMemoryItem call({ImportedMemoryItemKindEnum kind, String content});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfImportedMemoryItem.copyWith(...)` or call `instanceOfImportedMemoryItem.copyWith.fieldName(value)` for a single field.
class _$ImportedMemoryItemCWProxyImpl implements _$ImportedMemoryItemCWProxy {
  const _$ImportedMemoryItemCWProxyImpl(this._value);

  final ImportedMemoryItem _value;

  @override
  ImportedMemoryItem kind(ImportedMemoryItemKindEnum kind) => call(kind: kind);

  @override
  ImportedMemoryItem content(String content) => call(content: content);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ImportedMemoryItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ImportedMemoryItem(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ImportedMemoryItem call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? content = const $CopyWithPlaceholder(),
  }) {
    return ImportedMemoryItem(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as ImportedMemoryItemKindEnum,
      content: content == const $CopyWithPlaceholder() || content == null
          ? _value.content
          // ignore: cast_nullable_to_non_nullable
          : content as String,
    );
  }
}

extension $ImportedMemoryItemCopyWith on ImportedMemoryItem {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfImportedMemoryItem.copyWith(...)` or `instanceOfImportedMemoryItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ImportedMemoryItemCWProxy get copyWith =>
      _$ImportedMemoryItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportedMemoryItem _$ImportedMemoryItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ImportedMemoryItem', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['kind', 'content']);
      final val = ImportedMemoryItem(
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$ImportedMemoryItemKindEnumEnumMap, v),
        ),
        content: $checkedConvert('content', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ImportedMemoryItemToJson(ImportedMemoryItem instance) =>
    <String, dynamic>{
      'kind': _$ImportedMemoryItemKindEnumEnumMap[instance.kind]!,
      'content': instance.content,
    };

const _$ImportedMemoryItemKindEnumEnumMap = {
  ImportedMemoryItemKindEnum.fact: 'fact',
  ImportedMemoryItemKindEnum.preference: 'preference',
};

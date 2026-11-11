// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parse_memory_import_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ParseMemoryImportRequestCWProxy {
  ParseMemoryImportRequest text(String text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ParseMemoryImportRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ParseMemoryImportRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ParseMemoryImportRequest call({String text});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfParseMemoryImportRequest.copyWith(...)` or call `instanceOfParseMemoryImportRequest.copyWith.fieldName(value)` for a single field.
class _$ParseMemoryImportRequestCWProxyImpl
    implements _$ParseMemoryImportRequestCWProxy {
  const _$ParseMemoryImportRequestCWProxyImpl(this._value);

  final ParseMemoryImportRequest _value;

  @override
  ParseMemoryImportRequest text(String text) => call(text: text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ParseMemoryImportRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ParseMemoryImportRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ParseMemoryImportRequest call({Object? text = const $CopyWithPlaceholder()}) {
    return ParseMemoryImportRequest(
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $ParseMemoryImportRequestCopyWith on ParseMemoryImportRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfParseMemoryImportRequest.copyWith(...)` or `instanceOfParseMemoryImportRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ParseMemoryImportRequestCWProxy get copyWith =>
      _$ParseMemoryImportRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParseMemoryImportRequest _$ParseMemoryImportRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ParseMemoryImportRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['text']);
  final val = ParseMemoryImportRequest(
    text: $checkedConvert('text', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$ParseMemoryImportRequestToJson(
  ParseMemoryImportRequest instance,
) => <String, dynamic>{'text': instance.text};

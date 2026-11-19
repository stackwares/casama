// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paste_import_prompt.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PasteImportPromptCWProxy {
  PasteImportPrompt prompt(String prompt);

  PasteImportPrompt version(int version);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PasteImportPrompt(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PasteImportPrompt(...).copyWith(id: 12, name: "My name")
  /// ```
  PasteImportPrompt call({String prompt, int version});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPasteImportPrompt.copyWith(...)` or call `instanceOfPasteImportPrompt.copyWith.fieldName(value)` for a single field.
class _$PasteImportPromptCWProxyImpl implements _$PasteImportPromptCWProxy {
  const _$PasteImportPromptCWProxyImpl(this._value);

  final PasteImportPrompt _value;

  @override
  PasteImportPrompt prompt(String prompt) => call(prompt: prompt);

  @override
  PasteImportPrompt version(int version) => call(version: version);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PasteImportPrompt(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PasteImportPrompt(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PasteImportPrompt call({
    Object? prompt = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
  }) {
    return PasteImportPrompt(
      prompt: prompt == const $CopyWithPlaceholder() || prompt == null
          ? _value.prompt
          // ignore: cast_nullable_to_non_nullable
          : prompt as String,
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
    );
  }
}

extension $PasteImportPromptCopyWith on PasteImportPrompt {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPasteImportPrompt.copyWith(...)` or `instanceOfPasteImportPrompt.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PasteImportPromptCWProxy get copyWith =>
      _$PasteImportPromptCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PasteImportPrompt _$PasteImportPromptFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PasteImportPrompt', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['prompt', 'version']);
      final val = PasteImportPrompt(
        prompt: $checkedConvert('prompt', (v) => v as String),
        version: $checkedConvert('version', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$PasteImportPromptToJson(PasteImportPrompt instance) =>
    <String, dynamic>{'prompt': instance.prompt, 'version': instance.version};

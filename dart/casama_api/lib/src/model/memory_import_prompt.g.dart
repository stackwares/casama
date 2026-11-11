// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_import_prompt.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MemoryImportPromptCWProxy {
  MemoryImportPrompt prompt(String prompt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MemoryImportPrompt(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MemoryImportPrompt(...).copyWith(id: 12, name: "My name")
  /// ```
  MemoryImportPrompt call({String prompt});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMemoryImportPrompt.copyWith(...)` or call `instanceOfMemoryImportPrompt.copyWith.fieldName(value)` for a single field.
class _$MemoryImportPromptCWProxyImpl implements _$MemoryImportPromptCWProxy {
  const _$MemoryImportPromptCWProxyImpl(this._value);

  final MemoryImportPrompt _value;

  @override
  MemoryImportPrompt prompt(String prompt) => call(prompt: prompt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MemoryImportPrompt(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MemoryImportPrompt(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MemoryImportPrompt call({Object? prompt = const $CopyWithPlaceholder()}) {
    return MemoryImportPrompt(
      prompt: prompt == const $CopyWithPlaceholder() || prompt == null
          ? _value.prompt
          // ignore: cast_nullable_to_non_nullable
          : prompt as String,
    );
  }
}

extension $MemoryImportPromptCopyWith on MemoryImportPrompt {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMemoryImportPrompt.copyWith(...)` or `instanceOfMemoryImportPrompt.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MemoryImportPromptCWProxy get copyWith =>
      _$MemoryImportPromptCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemoryImportPrompt _$MemoryImportPromptFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MemoryImportPrompt', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['prompt']);
      final val = MemoryImportPrompt(
        prompt: $checkedConvert('prompt', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$MemoryImportPromptToJson(MemoryImportPrompt instance) =>
    <String, dynamic>{'prompt': instance.prompt};

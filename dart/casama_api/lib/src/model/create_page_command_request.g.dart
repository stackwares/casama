// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_page_command_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreatePageCommandRequestCWProxy {
  CreatePageCommandRequest name(String name);

  CreatePageCommandRequest prompt(String prompt);

  CreatePageCommandRequest position(int? position);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatePageCommandRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatePageCommandRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreatePageCommandRequest call({String name, String prompt, int? position});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreatePageCommandRequest.copyWith(...)` or call `instanceOfCreatePageCommandRequest.copyWith.fieldName(value)` for a single field.
class _$CreatePageCommandRequestCWProxyImpl
    implements _$CreatePageCommandRequestCWProxy {
  const _$CreatePageCommandRequestCWProxyImpl(this._value);

  final CreatePageCommandRequest _value;

  @override
  CreatePageCommandRequest name(String name) => call(name: name);

  @override
  CreatePageCommandRequest prompt(String prompt) => call(prompt: prompt);

  @override
  CreatePageCommandRequest position(int? position) => call(position: position);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatePageCommandRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatePageCommandRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreatePageCommandRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? prompt = const $CopyWithPlaceholder(),
    Object? position = const $CopyWithPlaceholder(),
  }) {
    return CreatePageCommandRequest(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      prompt: prompt == const $CopyWithPlaceholder() || prompt == null
          ? _value.prompt
          // ignore: cast_nullable_to_non_nullable
          : prompt as String,
      position: position == const $CopyWithPlaceholder()
          ? _value.position
          // ignore: cast_nullable_to_non_nullable
          : position as int?,
    );
  }
}

extension $CreatePageCommandRequestCopyWith on CreatePageCommandRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreatePageCommandRequest.copyWith(...)` or `instanceOfCreatePageCommandRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreatePageCommandRequestCWProxy get copyWith =>
      _$CreatePageCommandRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatePageCommandRequest _$CreatePageCommandRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreatePageCommandRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name', 'prompt']);
  final val = CreatePageCommandRequest(
    name: $checkedConvert('name', (v) => v as String),
    prompt: $checkedConvert('prompt', (v) => v as String),
    position: $checkedConvert('position', (v) => (v as num?)?.toInt()),
  );
  return val;
});

Map<String, dynamic> _$CreatePageCommandRequestToJson(
  CreatePageCommandRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'prompt': instance.prompt,
  'position': ?instance.position,
};

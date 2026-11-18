// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_page_command_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdatePageCommandRequestCWProxy {
  UpdatePageCommandRequest name(String? name);

  UpdatePageCommandRequest prompt(String? prompt);

  UpdatePageCommandRequest position(int? position);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdatePageCommandRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdatePageCommandRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdatePageCommandRequest call({String? name, String? prompt, int? position});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdatePageCommandRequest.copyWith(...)` or call `instanceOfUpdatePageCommandRequest.copyWith.fieldName(value)` for a single field.
class _$UpdatePageCommandRequestCWProxyImpl
    implements _$UpdatePageCommandRequestCWProxy {
  const _$UpdatePageCommandRequestCWProxyImpl(this._value);

  final UpdatePageCommandRequest _value;

  @override
  UpdatePageCommandRequest name(String? name) => call(name: name);

  @override
  UpdatePageCommandRequest prompt(String? prompt) => call(prompt: prompt);

  @override
  UpdatePageCommandRequest position(int? position) => call(position: position);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdatePageCommandRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdatePageCommandRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdatePageCommandRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? prompt = const $CopyWithPlaceholder(),
    Object? position = const $CopyWithPlaceholder(),
  }) {
    return UpdatePageCommandRequest(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      prompt: prompt == const $CopyWithPlaceholder()
          ? _value.prompt
          // ignore: cast_nullable_to_non_nullable
          : prompt as String?,
      position: position == const $CopyWithPlaceholder()
          ? _value.position
          // ignore: cast_nullable_to_non_nullable
          : position as int?,
    );
  }
}

extension $UpdatePageCommandRequestCopyWith on UpdatePageCommandRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdatePageCommandRequest.copyWith(...)` or `instanceOfUpdatePageCommandRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdatePageCommandRequestCWProxy get copyWith =>
      _$UpdatePageCommandRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdatePageCommandRequest _$UpdatePageCommandRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UpdatePageCommandRequest', json, ($checkedConvert) {
  final val = UpdatePageCommandRequest(
    name: $checkedConvert('name', (v) => v as String?),
    prompt: $checkedConvert('prompt', (v) => v as String?),
    position: $checkedConvert('position', (v) => (v as num?)?.toInt()),
  );
  return val;
});

Map<String, dynamic> _$UpdatePageCommandRequestToJson(
  UpdatePageCommandRequest instance,
) => <String, dynamic>{
  'name': ?instance.name,
  'prompt': ?instance.prompt,
  'position': ?instance.position,
};

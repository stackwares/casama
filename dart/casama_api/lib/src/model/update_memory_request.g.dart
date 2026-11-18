// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_memory_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateMemoryRequestCWProxy {
  UpdateMemoryRequest content(String? content);

  UpdateMemoryRequest pinned(bool? pinned);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateMemoryRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateMemoryRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateMemoryRequest call({String? content, bool? pinned});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateMemoryRequest.copyWith(...)` or call `instanceOfUpdateMemoryRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateMemoryRequestCWProxyImpl implements _$UpdateMemoryRequestCWProxy {
  const _$UpdateMemoryRequestCWProxyImpl(this._value);

  final UpdateMemoryRequest _value;

  @override
  UpdateMemoryRequest content(String? content) => call(content: content);

  @override
  UpdateMemoryRequest pinned(bool? pinned) => call(pinned: pinned);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateMemoryRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateMemoryRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateMemoryRequest call({
    Object? content = const $CopyWithPlaceholder(),
    Object? pinned = const $CopyWithPlaceholder(),
  }) {
    return UpdateMemoryRequest(
      content: content == const $CopyWithPlaceholder()
          ? _value.content
          // ignore: cast_nullable_to_non_nullable
          : content as String?,
      pinned: pinned == const $CopyWithPlaceholder()
          ? _value.pinned
          // ignore: cast_nullable_to_non_nullable
          : pinned as bool?,
    );
  }
}

extension $UpdateMemoryRequestCopyWith on UpdateMemoryRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateMemoryRequest.copyWith(...)` or `instanceOfUpdateMemoryRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateMemoryRequestCWProxy get copyWith =>
      _$UpdateMemoryRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateMemoryRequest _$UpdateMemoryRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdateMemoryRequest', json, ($checkedConvert) {
      final val = UpdateMemoryRequest(
        content: $checkedConvert('content', (v) => v as String?),
        pinned: $checkedConvert('pinned', (v) => v as bool?),
      );
      return val;
    });

Map<String, dynamic> _$UpdateMemoryRequestToJson(
  UpdateMemoryRequest instance,
) => <String, dynamic>{
  'content': ?instance.content,
  'pinned': ?instance.pinned,
};

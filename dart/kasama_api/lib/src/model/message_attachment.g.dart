// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_attachment.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MessageAttachmentCWProxy {
  MessageAttachment path(String path);

  MessageAttachment name(String name);

  MessageAttachment mimeType(String mimeType);

  MessageAttachment size(int size);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MessageAttachment(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MessageAttachment(...).copyWith(id: 12, name: "My name")
  /// ```
  MessageAttachment call({String path, String name, String mimeType, int size});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMessageAttachment.copyWith(...)` or call `instanceOfMessageAttachment.copyWith.fieldName(value)` for a single field.
class _$MessageAttachmentCWProxyImpl implements _$MessageAttachmentCWProxy {
  const _$MessageAttachmentCWProxyImpl(this._value);

  final MessageAttachment _value;

  @override
  MessageAttachment path(String path) => call(path: path);

  @override
  MessageAttachment name(String name) => call(name: name);

  @override
  MessageAttachment mimeType(String mimeType) => call(mimeType: mimeType);

  @override
  MessageAttachment size(int size) => call(size: size);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MessageAttachment(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MessageAttachment(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MessageAttachment call({
    Object? path = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? mimeType = const $CopyWithPlaceholder(),
    Object? size = const $CopyWithPlaceholder(),
  }) {
    return MessageAttachment(
      path: path == const $CopyWithPlaceholder() || path == null
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      mimeType: mimeType == const $CopyWithPlaceholder() || mimeType == null
          ? _value.mimeType
          // ignore: cast_nullable_to_non_nullable
          : mimeType as String,
      size: size == const $CopyWithPlaceholder() || size == null
          ? _value.size
          // ignore: cast_nullable_to_non_nullable
          : size as int,
    );
  }
}

extension $MessageAttachmentCopyWith on MessageAttachment {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMessageAttachment.copyWith(...)` or `instanceOfMessageAttachment.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MessageAttachmentCWProxy get copyWith =>
      _$MessageAttachmentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageAttachment _$MessageAttachmentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MessageAttachment', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['path', 'name', 'mime_type', 'size'],
      );
      final val = MessageAttachment(
        path: $checkedConvert('path', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        mimeType: $checkedConvert('mime_type', (v) => v as String),
        size: $checkedConvert('size', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'mimeType': 'mime_type'});

Map<String, dynamic> _$MessageAttachmentToJson(MessageAttachment instance) =>
    <String, dynamic>{
      'path': instance.path,
      'name': instance.name,
      'mime_type': instance.mimeType,
      'size': instance.size,
    };

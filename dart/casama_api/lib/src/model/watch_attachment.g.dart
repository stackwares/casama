// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_attachment.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchAttachmentCWProxy {
  WatchAttachment kind(WatchAttachmentKindEnum kind);

  WatchAttachment title(String title);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchAttachment(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchAttachment(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchAttachment call({WatchAttachmentKindEnum kind, String title});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchAttachment.copyWith(...)` or call `instanceOfWatchAttachment.copyWith.fieldName(value)` for a single field.
class _$WatchAttachmentCWProxyImpl implements _$WatchAttachmentCWProxy {
  const _$WatchAttachmentCWProxyImpl(this._value);

  final WatchAttachment _value;

  @override
  WatchAttachment kind(WatchAttachmentKindEnum kind) => call(kind: kind);

  @override
  WatchAttachment title(String title) => call(title: title);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchAttachment(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchAttachment(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchAttachment call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
  }) {
    return WatchAttachment(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as WatchAttachmentKindEnum,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
    );
  }
}

extension $WatchAttachmentCopyWith on WatchAttachment {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchAttachment.copyWith(...)` or `instanceOfWatchAttachment.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchAttachmentCWProxy get copyWith => _$WatchAttachmentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchAttachment _$WatchAttachmentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WatchAttachment', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['kind', 'title']);
      final val = WatchAttachment(
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$WatchAttachmentKindEnumEnumMap, v),
        ),
        title: $checkedConvert('title', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$WatchAttachmentToJson(WatchAttachment instance) =>
    <String, dynamic>{
      'kind': _$WatchAttachmentKindEnumEnumMap[instance.kind]!,
      'title': instance.title,
    };

const _$WatchAttachmentKindEnumEnumMap = {
  WatchAttachmentKindEnum.page: 'page',
  WatchAttachmentKindEnum.image: 'image',
  WatchAttachmentKindEnum.video: 'video',
  WatchAttachmentKindEnum.audio: 'audio',
  WatchAttachmentKindEnum.document: 'document',
  WatchAttachmentKindEnum.file: 'file',
  WatchAttachmentKindEnum.card: 'card',
  WatchAttachmentKindEnum.link: 'link',
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_profile_photo_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetProfilePhotoRequestCWProxy {
  SetProfilePhotoRequest contentType(
    SetProfilePhotoRequestContentTypeEnum contentType,
  );

  SetProfilePhotoRequest data(String data);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetProfilePhotoRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetProfilePhotoRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetProfilePhotoRequest call({
    SetProfilePhotoRequestContentTypeEnum contentType,
    String data,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetProfilePhotoRequest.copyWith(...)` or call `instanceOfSetProfilePhotoRequest.copyWith.fieldName(value)` for a single field.
class _$SetProfilePhotoRequestCWProxyImpl
    implements _$SetProfilePhotoRequestCWProxy {
  const _$SetProfilePhotoRequestCWProxyImpl(this._value);

  final SetProfilePhotoRequest _value;

  @override
  SetProfilePhotoRequest contentType(
    SetProfilePhotoRequestContentTypeEnum contentType,
  ) => call(contentType: contentType);

  @override
  SetProfilePhotoRequest data(String data) => call(data: data);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetProfilePhotoRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetProfilePhotoRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetProfilePhotoRequest call({
    Object? contentType = const $CopyWithPlaceholder(),
    Object? data = const $CopyWithPlaceholder(),
  }) {
    return SetProfilePhotoRequest(
      contentType:
          contentType == const $CopyWithPlaceholder() || contentType == null
          ? _value.contentType
          // ignore: cast_nullable_to_non_nullable
          : contentType as SetProfilePhotoRequestContentTypeEnum,
      data: data == const $CopyWithPlaceholder() || data == null
          ? _value.data
          // ignore: cast_nullable_to_non_nullable
          : data as String,
    );
  }
}

extension $SetProfilePhotoRequestCopyWith on SetProfilePhotoRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetProfilePhotoRequest.copyWith(...)` or `instanceOfSetProfilePhotoRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetProfilePhotoRequestCWProxy get copyWith =>
      _$SetProfilePhotoRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetProfilePhotoRequest _$SetProfilePhotoRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SetProfilePhotoRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['content_type', 'data']);
  final val = SetProfilePhotoRequest(
    contentType: $checkedConvert(
      'content_type',
      (v) => $enumDecode(_$SetProfilePhotoRequestContentTypeEnumEnumMap, v),
    ),
    data: $checkedConvert('data', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'contentType': 'content_type'});

Map<String, dynamic> _$SetProfilePhotoRequestToJson(
  SetProfilePhotoRequest instance,
) => <String, dynamic>{
  'content_type':
      _$SetProfilePhotoRequestContentTypeEnumEnumMap[instance.contentType]!,
  'data': instance.data,
};

const _$SetProfilePhotoRequestContentTypeEnumEnumMap = {
  SetProfilePhotoRequestContentTypeEnum.imageSlashJpeg: 'image/jpeg',
  SetProfilePhotoRequestContentTypeEnum.imageSlashPng: 'image/png',
  SetProfilePhotoRequestContentTypeEnum.imageSlashWebp: 'image/webp',
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_bot_picture_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetBotPictureRequestCWProxy {
  SetBotPictureRequest data(String data);

  SetBotPictureRequest original(String? original);

  SetBotPictureRequest crop(BotPictureCrop? crop);

  SetBotPictureRequest source_(SetBotPictureRequestSource_Enum? source_);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetBotPictureRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetBotPictureRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetBotPictureRequest call({
    String data,
    String? original,
    BotPictureCrop? crop,
    SetBotPictureRequestSource_Enum? source_,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetBotPictureRequest.copyWith(...)` or call `instanceOfSetBotPictureRequest.copyWith.fieldName(value)` for a single field.
class _$SetBotPictureRequestCWProxyImpl
    implements _$SetBotPictureRequestCWProxy {
  const _$SetBotPictureRequestCWProxyImpl(this._value);

  final SetBotPictureRequest _value;

  @override
  SetBotPictureRequest data(String data) => call(data: data);

  @override
  SetBotPictureRequest original(String? original) => call(original: original);

  @override
  SetBotPictureRequest crop(BotPictureCrop? crop) => call(crop: crop);

  @override
  SetBotPictureRequest source_(SetBotPictureRequestSource_Enum? source_) =>
      call(source_: source_);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetBotPictureRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetBotPictureRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetBotPictureRequest call({
    Object? data = const $CopyWithPlaceholder(),
    Object? original = const $CopyWithPlaceholder(),
    Object? crop = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
  }) {
    return SetBotPictureRequest(
      data: data == const $CopyWithPlaceholder() || data == null
          ? _value.data
          // ignore: cast_nullable_to_non_nullable
          : data as String,
      original: original == const $CopyWithPlaceholder()
          ? _value.original
          // ignore: cast_nullable_to_non_nullable
          : original as String?,
      crop: crop == const $CopyWithPlaceholder()
          ? _value.crop
          // ignore: cast_nullable_to_non_nullable
          : crop as BotPictureCrop?,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as SetBotPictureRequestSource_Enum?,
    );
  }
}

extension $SetBotPictureRequestCopyWith on SetBotPictureRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetBotPictureRequest.copyWith(...)` or `instanceOfSetBotPictureRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetBotPictureRequestCWProxy get copyWith =>
      _$SetBotPictureRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetBotPictureRequest _$SetBotPictureRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SetBotPictureRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['data']);
  final val = SetBotPictureRequest(
    data: $checkedConvert('data', (v) => v as String),
    original: $checkedConvert('original', (v) => v as String?),
    crop: $checkedConvert(
      'crop',
      (v) =>
          v == null ? null : BotPictureCrop.fromJson(v as Map<String, dynamic>),
    ),
    source_: $checkedConvert(
      'source',
      (v) => $enumDecodeNullable(_$SetBotPictureRequestSource_EnumEnumMap, v),
    ),
  );
  return val;
}, fieldKeyMap: const {'source_': 'source'});

Map<String, dynamic> _$SetBotPictureRequestToJson(
  SetBotPictureRequest instance,
) => <String, dynamic>{
  'data': instance.data,
  'original': ?instance.original,
  'crop': ?instance.crop?.toJson(),
  'source': ?_$SetBotPictureRequestSource_EnumEnumMap[instance.source_],
};

const _$SetBotPictureRequestSource_EnumEnumMap = {
  SetBotPictureRequestSource_Enum.upload: 'upload',
  SetBotPictureRequestSource_Enum.chat: 'chat',
};

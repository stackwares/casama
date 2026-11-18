// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_models.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CloudModelsCWProxy {
  CloudModels chat(String chat);

  CloudModels background(String background);

  CloudModels image(String image);

  CloudModels imageResolution(CloudModelsImageResolutionEnum imageResolution);

  CloudModels live(String live);

  CloudModels tts(String tts);

  CloudModels stt(String stt);

  CloudModels embedding(String embedding);

  CloudModels video(String video);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CloudModels(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CloudModels(...).copyWith(id: 12, name: "My name")
  /// ```
  CloudModels call({
    String chat,
    String background,
    String image,
    CloudModelsImageResolutionEnum imageResolution,
    String live,
    String tts,
    String stt,
    String embedding,
    String video,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCloudModels.copyWith(...)` or call `instanceOfCloudModels.copyWith.fieldName(value)` for a single field.
class _$CloudModelsCWProxyImpl implements _$CloudModelsCWProxy {
  const _$CloudModelsCWProxyImpl(this._value);

  final CloudModels _value;

  @override
  CloudModels chat(String chat) => call(chat: chat);

  @override
  CloudModels background(String background) => call(background: background);

  @override
  CloudModels image(String image) => call(image: image);

  @override
  CloudModels imageResolution(CloudModelsImageResolutionEnum imageResolution) =>
      call(imageResolution: imageResolution);

  @override
  CloudModels live(String live) => call(live: live);

  @override
  CloudModels tts(String tts) => call(tts: tts);

  @override
  CloudModels stt(String stt) => call(stt: stt);

  @override
  CloudModels embedding(String embedding) => call(embedding: embedding);

  @override
  CloudModels video(String video) => call(video: video);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CloudModels(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CloudModels(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CloudModels call({
    Object? chat = const $CopyWithPlaceholder(),
    Object? background = const $CopyWithPlaceholder(),
    Object? image = const $CopyWithPlaceholder(),
    Object? imageResolution = const $CopyWithPlaceholder(),
    Object? live = const $CopyWithPlaceholder(),
    Object? tts = const $CopyWithPlaceholder(),
    Object? stt = const $CopyWithPlaceholder(),
    Object? embedding = const $CopyWithPlaceholder(),
    Object? video = const $CopyWithPlaceholder(),
  }) {
    return CloudModels(
      chat: chat == const $CopyWithPlaceholder() || chat == null
          ? _value.chat
          // ignore: cast_nullable_to_non_nullable
          : chat as String,
      background:
          background == const $CopyWithPlaceholder() || background == null
          ? _value.background
          // ignore: cast_nullable_to_non_nullable
          : background as String,
      image: image == const $CopyWithPlaceholder() || image == null
          ? _value.image
          // ignore: cast_nullable_to_non_nullable
          : image as String,
      imageResolution:
          imageResolution == const $CopyWithPlaceholder() ||
              imageResolution == null
          ? _value.imageResolution
          // ignore: cast_nullable_to_non_nullable
          : imageResolution as CloudModelsImageResolutionEnum,
      live: live == const $CopyWithPlaceholder() || live == null
          ? _value.live
          // ignore: cast_nullable_to_non_nullable
          : live as String,
      tts: tts == const $CopyWithPlaceholder() || tts == null
          ? _value.tts
          // ignore: cast_nullable_to_non_nullable
          : tts as String,
      stt: stt == const $CopyWithPlaceholder() || stt == null
          ? _value.stt
          // ignore: cast_nullable_to_non_nullable
          : stt as String,
      embedding: embedding == const $CopyWithPlaceholder() || embedding == null
          ? _value.embedding
          // ignore: cast_nullable_to_non_nullable
          : embedding as String,
      video: video == const $CopyWithPlaceholder() || video == null
          ? _value.video
          // ignore: cast_nullable_to_non_nullable
          : video as String,
    );
  }
}

extension $CloudModelsCopyWith on CloudModels {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCloudModels.copyWith(...)` or `instanceOfCloudModels.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CloudModelsCWProxy get copyWith => _$CloudModelsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CloudModels _$CloudModelsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CloudModels', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'chat',
          'background',
          'image',
          'image_resolution',
          'live',
          'tts',
          'stt',
          'embedding',
          'video',
        ],
      );
      final val = CloudModels(
        chat: $checkedConvert('chat', (v) => v as String),
        background: $checkedConvert('background', (v) => v as String),
        image: $checkedConvert('image', (v) => v as String),
        imageResolution: $checkedConvert(
          'image_resolution',
          (v) => $enumDecode(_$CloudModelsImageResolutionEnumEnumMap, v),
        ),
        live: $checkedConvert('live', (v) => v as String),
        tts: $checkedConvert('tts', (v) => v as String),
        stt: $checkedConvert('stt', (v) => v as String),
        embedding: $checkedConvert('embedding', (v) => v as String),
        video: $checkedConvert('video', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'imageResolution': 'image_resolution'});

Map<String, dynamic> _$CloudModelsToJson(CloudModels instance) =>
    <String, dynamic>{
      'chat': instance.chat,
      'background': instance.background,
      'image': instance.image,
      'image_resolution':
          _$CloudModelsImageResolutionEnumEnumMap[instance.imageResolution]!,
      'live': instance.live,
      'tts': instance.tts,
      'stt': instance.stt,
      'embedding': instance.embedding,
      'video': instance.video,
    };

const _$CloudModelsImageResolutionEnumEnumMap = {
  CloudModelsImageResolutionEnum.n1k: '1K',
  CloudModelsImageResolutionEnum.n2k: '2K',
  CloudModelsImageResolutionEnum.n4k: '4K',
};

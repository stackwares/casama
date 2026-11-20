// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_picture.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotPictureCWProxy {
  BotPicture id(String id);

  BotPicture avatarUrl(String avatarUrl);

  BotPicture source_(BotPictureSource_Enum source_);

  BotPicture inUse(bool inUse);

  BotPicture hasOriginal(bool hasOriginal);

  BotPicture crop(BotPictureCrop? crop);

  BotPicture createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotPicture(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotPicture(...).copyWith(id: 12, name: "My name")
  /// ```
  BotPicture call({
    String id,
    String avatarUrl,
    BotPictureSource_Enum source_,
    bool inUse,
    bool hasOriginal,
    BotPictureCrop? crop,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotPicture.copyWith(...)` or call `instanceOfBotPicture.copyWith.fieldName(value)` for a single field.
class _$BotPictureCWProxyImpl implements _$BotPictureCWProxy {
  const _$BotPictureCWProxyImpl(this._value);

  final BotPicture _value;

  @override
  BotPicture id(String id) => call(id: id);

  @override
  BotPicture avatarUrl(String avatarUrl) => call(avatarUrl: avatarUrl);

  @override
  BotPicture source_(BotPictureSource_Enum source_) => call(source_: source_);

  @override
  BotPicture inUse(bool inUse) => call(inUse: inUse);

  @override
  BotPicture hasOriginal(bool hasOriginal) => call(hasOriginal: hasOriginal);

  @override
  BotPicture crop(BotPictureCrop? crop) => call(crop: crop);

  @override
  BotPicture createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotPicture(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotPicture(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotPicture call({
    Object? id = const $CopyWithPlaceholder(),
    Object? avatarUrl = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? inUse = const $CopyWithPlaceholder(),
    Object? hasOriginal = const $CopyWithPlaceholder(),
    Object? crop = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return BotPicture(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      avatarUrl: avatarUrl == const $CopyWithPlaceholder() || avatarUrl == null
          ? _value.avatarUrl
          // ignore: cast_nullable_to_non_nullable
          : avatarUrl as String,
      source_: source_ == const $CopyWithPlaceholder() || source_ == null
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as BotPictureSource_Enum,
      inUse: inUse == const $CopyWithPlaceholder() || inUse == null
          ? _value.inUse
          // ignore: cast_nullable_to_non_nullable
          : inUse as bool,
      hasOriginal:
          hasOriginal == const $CopyWithPlaceholder() || hasOriginal == null
          ? _value.hasOriginal
          // ignore: cast_nullable_to_non_nullable
          : hasOriginal as bool,
      crop: crop == const $CopyWithPlaceholder()
          ? _value.crop
          // ignore: cast_nullable_to_non_nullable
          : crop as BotPictureCrop?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $BotPictureCopyWith on BotPicture {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotPicture.copyWith(...)` or `instanceOfBotPicture.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotPictureCWProxy get copyWith => _$BotPictureCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotPicture _$BotPictureFromJson(Map<String, dynamic> json) => $checkedCreate(
  'BotPicture',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'avatar_url',
        'source',
        'in_use',
        'has_original',
        'created_at',
      ],
    );
    final val = BotPicture(
      id: $checkedConvert('id', (v) => v as String),
      avatarUrl: $checkedConvert('avatar_url', (v) => v as String),
      source_: $checkedConvert(
        'source',
        (v) => $enumDecode(_$BotPictureSource_EnumEnumMap, v),
      ),
      inUse: $checkedConvert('in_use', (v) => v as bool),
      hasOriginal: $checkedConvert('has_original', (v) => v as bool),
      crop: $checkedConvert(
        'crop',
        (v) => v == null
            ? null
            : BotPictureCrop.fromJson(v as Map<String, dynamic>),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'avatarUrl': 'avatar_url',
    'source_': 'source',
    'inUse': 'in_use',
    'hasOriginal': 'has_original',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$BotPictureToJson(BotPicture instance) =>
    <String, dynamic>{
      'id': instance.id,
      'avatar_url': instance.avatarUrl,
      'source': _$BotPictureSource_EnumEnumMap[instance.source_]!,
      'in_use': instance.inUse,
      'has_original': instance.hasOriginal,
      'crop': ?instance.crop?.toJson(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$BotPictureSource_EnumEnumMap = {
  BotPictureSource_Enum.upload: 'upload',
  BotPictureSource_Enum.chat: 'chat',
  BotPictureSource_Enum.generated: 'generated',
  BotPictureSource_Enum.bot: 'bot',
};

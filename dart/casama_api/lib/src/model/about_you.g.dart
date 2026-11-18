// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'about_you.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AboutYouCWProxy {
  AboutYou displayName(String? displayName);

  AboutYou preferredName(String? preferredName);

  AboutYou pronouns(String? pronouns);

  AboutYou about(String about);

  AboutYou replyStyle(String replyStyle);

  AboutYou learn(bool learn);

  AboutYou nameAsked(bool nameAsked);

  AboutYou photoId(String? photoId);

  AboutYou providerPhoto(bool? providerPhoto);

  AboutYou photoImportTried(bool? photoImportTried);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AboutYou(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AboutYou(...).copyWith(id: 12, name: "My name")
  /// ```
  AboutYou call({
    String? displayName,
    String? preferredName,
    String? pronouns,
    String about,
    String replyStyle,
    bool learn,
    bool nameAsked,
    String? photoId,
    bool? providerPhoto,
    bool? photoImportTried,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAboutYou.copyWith(...)` or call `instanceOfAboutYou.copyWith.fieldName(value)` for a single field.
class _$AboutYouCWProxyImpl implements _$AboutYouCWProxy {
  const _$AboutYouCWProxyImpl(this._value);

  final AboutYou _value;

  @override
  AboutYou displayName(String? displayName) => call(displayName: displayName);

  @override
  AboutYou preferredName(String? preferredName) =>
      call(preferredName: preferredName);

  @override
  AboutYou pronouns(String? pronouns) => call(pronouns: pronouns);

  @override
  AboutYou about(String about) => call(about: about);

  @override
  AboutYou replyStyle(String replyStyle) => call(replyStyle: replyStyle);

  @override
  AboutYou learn(bool learn) => call(learn: learn);

  @override
  AboutYou nameAsked(bool nameAsked) => call(nameAsked: nameAsked);

  @override
  AboutYou photoId(String? photoId) => call(photoId: photoId);

  @override
  AboutYou providerPhoto(bool? providerPhoto) =>
      call(providerPhoto: providerPhoto);

  @override
  AboutYou photoImportTried(bool? photoImportTried) =>
      call(photoImportTried: photoImportTried);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AboutYou(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AboutYou(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AboutYou call({
    Object? displayName = const $CopyWithPlaceholder(),
    Object? preferredName = const $CopyWithPlaceholder(),
    Object? pronouns = const $CopyWithPlaceholder(),
    Object? about = const $CopyWithPlaceholder(),
    Object? replyStyle = const $CopyWithPlaceholder(),
    Object? learn = const $CopyWithPlaceholder(),
    Object? nameAsked = const $CopyWithPlaceholder(),
    Object? photoId = const $CopyWithPlaceholder(),
    Object? providerPhoto = const $CopyWithPlaceholder(),
    Object? photoImportTried = const $CopyWithPlaceholder(),
  }) {
    return AboutYou(
      displayName: displayName == const $CopyWithPlaceholder()
          ? _value.displayName
          // ignore: cast_nullable_to_non_nullable
          : displayName as String?,
      preferredName: preferredName == const $CopyWithPlaceholder()
          ? _value.preferredName
          // ignore: cast_nullable_to_non_nullable
          : preferredName as String?,
      pronouns: pronouns == const $CopyWithPlaceholder()
          ? _value.pronouns
          // ignore: cast_nullable_to_non_nullable
          : pronouns as String?,
      about: about == const $CopyWithPlaceholder() || about == null
          ? _value.about
          // ignore: cast_nullable_to_non_nullable
          : about as String,
      replyStyle:
          replyStyle == const $CopyWithPlaceholder() || replyStyle == null
          ? _value.replyStyle
          // ignore: cast_nullable_to_non_nullable
          : replyStyle as String,
      learn: learn == const $CopyWithPlaceholder() || learn == null
          ? _value.learn
          // ignore: cast_nullable_to_non_nullable
          : learn as bool,
      nameAsked: nameAsked == const $CopyWithPlaceholder() || nameAsked == null
          ? _value.nameAsked
          // ignore: cast_nullable_to_non_nullable
          : nameAsked as bool,
      photoId: photoId == const $CopyWithPlaceholder()
          ? _value.photoId
          // ignore: cast_nullable_to_non_nullable
          : photoId as String?,
      providerPhoto: providerPhoto == const $CopyWithPlaceholder()
          ? _value.providerPhoto
          // ignore: cast_nullable_to_non_nullable
          : providerPhoto as bool?,
      photoImportTried: photoImportTried == const $CopyWithPlaceholder()
          ? _value.photoImportTried
          // ignore: cast_nullable_to_non_nullable
          : photoImportTried as bool?,
    );
  }
}

extension $AboutYouCopyWith on AboutYou {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAboutYou.copyWith(...)` or `instanceOfAboutYou.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AboutYouCWProxy get copyWith => _$AboutYouCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AboutYou _$AboutYouFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AboutYou',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'display_name',
        'preferred_name',
        'pronouns',
        'about',
        'reply_style',
        'learn',
        'name_asked',
      ],
    );
    final val = AboutYou(
      displayName: $checkedConvert('display_name', (v) => v as String?),
      preferredName: $checkedConvert('preferred_name', (v) => v as String?),
      pronouns: $checkedConvert('pronouns', (v) => v as String?),
      about: $checkedConvert('about', (v) => v as String),
      replyStyle: $checkedConvert('reply_style', (v) => v as String),
      learn: $checkedConvert('learn', (v) => v as bool),
      nameAsked: $checkedConvert('name_asked', (v) => v as bool),
      photoId: $checkedConvert('photo_id', (v) => v as String?),
      providerPhoto: $checkedConvert('provider_photo', (v) => v as bool?),
      photoImportTried: $checkedConvert(
        'photo_import_tried',
        (v) => v as bool?,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'displayName': 'display_name',
    'preferredName': 'preferred_name',
    'replyStyle': 'reply_style',
    'nameAsked': 'name_asked',
    'photoId': 'photo_id',
    'providerPhoto': 'provider_photo',
    'photoImportTried': 'photo_import_tried',
  },
);

Map<String, dynamic> _$AboutYouToJson(AboutYou instance) => <String, dynamic>{
  'display_name': instance.displayName,
  'preferred_name': instance.preferredName,
  'pronouns': instance.pronouns,
  'about': instance.about,
  'reply_style': instance.replyStyle,
  'learn': instance.learn,
  'name_asked': instance.nameAsked,
  'photo_id': ?instance.photoId,
  'provider_photo': ?instance.providerPhoto,
  'photo_import_tried': ?instance.photoImportTried,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_about_you_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateAboutYouRequestCWProxy {
  UpdateAboutYouRequest preferredName(String? preferredName);

  UpdateAboutYouRequest pronouns(String? pronouns);

  UpdateAboutYouRequest about(String? about);

  UpdateAboutYouRequest replyStyle(String? replyStyle);

  UpdateAboutYouRequest learn(bool? learn);

  UpdateAboutYouRequest nameAsked(bool? nameAsked);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateAboutYouRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateAboutYouRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateAboutYouRequest call({
    String? preferredName,
    String? pronouns,
    String? about,
    String? replyStyle,
    bool? learn,
    bool? nameAsked,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateAboutYouRequest.copyWith(...)` or call `instanceOfUpdateAboutYouRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateAboutYouRequestCWProxyImpl
    implements _$UpdateAboutYouRequestCWProxy {
  const _$UpdateAboutYouRequestCWProxyImpl(this._value);

  final UpdateAboutYouRequest _value;

  @override
  UpdateAboutYouRequest preferredName(String? preferredName) =>
      call(preferredName: preferredName);

  @override
  UpdateAboutYouRequest pronouns(String? pronouns) => call(pronouns: pronouns);

  @override
  UpdateAboutYouRequest about(String? about) => call(about: about);

  @override
  UpdateAboutYouRequest replyStyle(String? replyStyle) =>
      call(replyStyle: replyStyle);

  @override
  UpdateAboutYouRequest learn(bool? learn) => call(learn: learn);

  @override
  UpdateAboutYouRequest nameAsked(bool? nameAsked) =>
      call(nameAsked: nameAsked);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateAboutYouRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateAboutYouRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateAboutYouRequest call({
    Object? preferredName = const $CopyWithPlaceholder(),
    Object? pronouns = const $CopyWithPlaceholder(),
    Object? about = const $CopyWithPlaceholder(),
    Object? replyStyle = const $CopyWithPlaceholder(),
    Object? learn = const $CopyWithPlaceholder(),
    Object? nameAsked = const $CopyWithPlaceholder(),
  }) {
    return UpdateAboutYouRequest(
      preferredName: preferredName == const $CopyWithPlaceholder()
          ? _value.preferredName
          // ignore: cast_nullable_to_non_nullable
          : preferredName as String?,
      pronouns: pronouns == const $CopyWithPlaceholder()
          ? _value.pronouns
          // ignore: cast_nullable_to_non_nullable
          : pronouns as String?,
      about: about == const $CopyWithPlaceholder()
          ? _value.about
          // ignore: cast_nullable_to_non_nullable
          : about as String?,
      replyStyle: replyStyle == const $CopyWithPlaceholder()
          ? _value.replyStyle
          // ignore: cast_nullable_to_non_nullable
          : replyStyle as String?,
      learn: learn == const $CopyWithPlaceholder()
          ? _value.learn
          // ignore: cast_nullable_to_non_nullable
          : learn as bool?,
      nameAsked: nameAsked == const $CopyWithPlaceholder()
          ? _value.nameAsked
          // ignore: cast_nullable_to_non_nullable
          : nameAsked as bool?,
    );
  }
}

extension $UpdateAboutYouRequestCopyWith on UpdateAboutYouRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateAboutYouRequest.copyWith(...)` or `instanceOfUpdateAboutYouRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateAboutYouRequestCWProxy get copyWith =>
      _$UpdateAboutYouRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateAboutYouRequest _$UpdateAboutYouRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'UpdateAboutYouRequest',
  json,
  ($checkedConvert) {
    final val = UpdateAboutYouRequest(
      preferredName: $checkedConvert('preferred_name', (v) => v as String?),
      pronouns: $checkedConvert('pronouns', (v) => v as String?),
      about: $checkedConvert('about', (v) => v as String?),
      replyStyle: $checkedConvert('reply_style', (v) => v as String?),
      learn: $checkedConvert('learn', (v) => v as bool?),
      nameAsked: $checkedConvert('name_asked', (v) => v as bool?),
    );
    return val;
  },
  fieldKeyMap: const {
    'preferredName': 'preferred_name',
    'replyStyle': 'reply_style',
    'nameAsked': 'name_asked',
  },
);

Map<String, dynamic> _$UpdateAboutYouRequestToJson(
  UpdateAboutYouRequest instance,
) => <String, dynamic>{
  'preferred_name': ?instance.preferredName,
  'pronouns': ?instance.pronouns,
  'about': ?instance.about,
  'reply_style': ?instance.replyStyle,
  'learn': ?instance.learn,
  'name_asked': ?instance.nameAsked,
};

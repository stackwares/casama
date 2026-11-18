// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_preferences.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EmailPreferencesCWProxy {
  EmailPreferences tips(bool tips);

  EmailPreferences galleryDigest(bool? galleryDigest);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EmailPreferences(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EmailPreferences(...).copyWith(id: 12, name: "My name")
  /// ```
  EmailPreferences call({bool tips, bool? galleryDigest});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfEmailPreferences.copyWith(...)` or call `instanceOfEmailPreferences.copyWith.fieldName(value)` for a single field.
class _$EmailPreferencesCWProxyImpl implements _$EmailPreferencesCWProxy {
  const _$EmailPreferencesCWProxyImpl(this._value);

  final EmailPreferences _value;

  @override
  EmailPreferences tips(bool tips) => call(tips: tips);

  @override
  EmailPreferences galleryDigest(bool? galleryDigest) =>
      call(galleryDigest: galleryDigest);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EmailPreferences(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EmailPreferences(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  EmailPreferences call({
    Object? tips = const $CopyWithPlaceholder(),
    Object? galleryDigest = const $CopyWithPlaceholder(),
  }) {
    return EmailPreferences(
      tips: tips == const $CopyWithPlaceholder() || tips == null
          ? _value.tips
          // ignore: cast_nullable_to_non_nullable
          : tips as bool,
      galleryDigest: galleryDigest == const $CopyWithPlaceholder()
          ? _value.galleryDigest
          // ignore: cast_nullable_to_non_nullable
          : galleryDigest as bool?,
    );
  }
}

extension $EmailPreferencesCopyWith on EmailPreferences {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfEmailPreferences.copyWith(...)` or `instanceOfEmailPreferences.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EmailPreferencesCWProxy get copyWith => _$EmailPreferencesCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailPreferences _$EmailPreferencesFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EmailPreferences', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['tips']);
      final val = EmailPreferences(
        tips: $checkedConvert('tips', (v) => v as bool),
        galleryDigest: $checkedConvert('gallery_digest', (v) => v as bool?),
      );
      return val;
    }, fieldKeyMap: const {'galleryDigest': 'gallery_digest'});

Map<String, dynamic> _$EmailPreferencesToJson(EmailPreferences instance) =>
    <String, dynamic>{
      'tips': instance.tips,
      'gallery_digest': ?instance.galleryDigest,
    };

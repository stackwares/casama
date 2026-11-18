// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'newsletter_status.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NewsletterStatusCWProxy {
  NewsletterStatus available(bool available);

  NewsletterStatus subscribed(bool subscribed);

  NewsletterStatus asked(bool asked);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `NewsletterStatus(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// NewsletterStatus(...).copyWith(id: 12, name: "My name")
  /// ```
  NewsletterStatus call({bool available, bool subscribed, bool asked});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfNewsletterStatus.copyWith(...)` or call `instanceOfNewsletterStatus.copyWith.fieldName(value)` for a single field.
class _$NewsletterStatusCWProxyImpl implements _$NewsletterStatusCWProxy {
  const _$NewsletterStatusCWProxyImpl(this._value);

  final NewsletterStatus _value;

  @override
  NewsletterStatus available(bool available) => call(available: available);

  @override
  NewsletterStatus subscribed(bool subscribed) => call(subscribed: subscribed);

  @override
  NewsletterStatus asked(bool asked) => call(asked: asked);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `NewsletterStatus(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// NewsletterStatus(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  NewsletterStatus call({
    Object? available = const $CopyWithPlaceholder(),
    Object? subscribed = const $CopyWithPlaceholder(),
    Object? asked = const $CopyWithPlaceholder(),
  }) {
    return NewsletterStatus(
      available: available == const $CopyWithPlaceholder() || available == null
          ? _value.available
          // ignore: cast_nullable_to_non_nullable
          : available as bool,
      subscribed:
          subscribed == const $CopyWithPlaceholder() || subscribed == null
          ? _value.subscribed
          // ignore: cast_nullable_to_non_nullable
          : subscribed as bool,
      asked: asked == const $CopyWithPlaceholder() || asked == null
          ? _value.asked
          // ignore: cast_nullable_to_non_nullable
          : asked as bool,
    );
  }
}

extension $NewsletterStatusCopyWith on NewsletterStatus {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfNewsletterStatus.copyWith(...)` or `instanceOfNewsletterStatus.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NewsletterStatusCWProxy get copyWith => _$NewsletterStatusCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewsletterStatus _$NewsletterStatusFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NewsletterStatus', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['available', 'subscribed', 'asked'],
      );
      final val = NewsletterStatus(
        available: $checkedConvert('available', (v) => v as bool),
        subscribed: $checkedConvert('subscribed', (v) => v as bool),
        asked: $checkedConvert('asked', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$NewsletterStatusToJson(NewsletterStatus instance) =>
    <String, dynamic>{
      'available': instance.available,
      'subscribed': instance.subscribed,
      'asked': instance.asked,
    };

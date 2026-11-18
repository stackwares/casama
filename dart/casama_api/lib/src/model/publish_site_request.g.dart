// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publish_site_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublishSiteRequestCWProxy {
  PublishSiteRequest label(String? label);

  PublishSiteRequest indexable(bool? indexable);

  PublishSiteRequest badge(bool? badge);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublishSiteRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublishSiteRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  PublishSiteRequest call({String? label, bool? indexable, bool? badge});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPublishSiteRequest.copyWith(...)` or call `instanceOfPublishSiteRequest.copyWith.fieldName(value)` for a single field.
class _$PublishSiteRequestCWProxyImpl implements _$PublishSiteRequestCWProxy {
  const _$PublishSiteRequestCWProxyImpl(this._value);

  final PublishSiteRequest _value;

  @override
  PublishSiteRequest label(String? label) => call(label: label);

  @override
  PublishSiteRequest indexable(bool? indexable) => call(indexable: indexable);

  @override
  PublishSiteRequest badge(bool? badge) => call(badge: badge);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublishSiteRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublishSiteRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PublishSiteRequest call({
    Object? label = const $CopyWithPlaceholder(),
    Object? indexable = const $CopyWithPlaceholder(),
    Object? badge = const $CopyWithPlaceholder(),
  }) {
    return PublishSiteRequest(
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String?,
      indexable: indexable == const $CopyWithPlaceholder()
          ? _value.indexable
          // ignore: cast_nullable_to_non_nullable
          : indexable as bool?,
      badge: badge == const $CopyWithPlaceholder()
          ? _value.badge
          // ignore: cast_nullable_to_non_nullable
          : badge as bool?,
    );
  }
}

extension $PublishSiteRequestCopyWith on PublishSiteRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPublishSiteRequest.copyWith(...)` or `instanceOfPublishSiteRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublishSiteRequestCWProxy get copyWith =>
      _$PublishSiteRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublishSiteRequest _$PublishSiteRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PublishSiteRequest', json, ($checkedConvert) {
      final val = PublishSiteRequest(
        label: $checkedConvert('label', (v) => v as String?),
        indexable: $checkedConvert('indexable', (v) => v as bool?),
        badge: $checkedConvert('badge', (v) => v as bool?),
      );
      return val;
    });

Map<String, dynamic> _$PublishSiteRequestToJson(PublishSiteRequest instance) =>
    <String, dynamic>{
      'label': ?instance.label,
      'indexable': ?instance.indexable,
      'badge': ?instance.badge,
    };

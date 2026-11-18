// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_submission_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GallerySubmissionListCWProxy {
  GallerySubmissionList items(List<GallerySubmission> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GallerySubmissionList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GallerySubmissionList(...).copyWith(id: 12, name: "My name")
  /// ```
  GallerySubmissionList call({List<GallerySubmission> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGallerySubmissionList.copyWith(...)` or call `instanceOfGallerySubmissionList.copyWith.fieldName(value)` for a single field.
class _$GallerySubmissionListCWProxyImpl
    implements _$GallerySubmissionListCWProxy {
  const _$GallerySubmissionListCWProxyImpl(this._value);

  final GallerySubmissionList _value;

  @override
  GallerySubmissionList items(List<GallerySubmission> items) =>
      call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GallerySubmissionList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GallerySubmissionList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GallerySubmissionList call({Object? items = const $CopyWithPlaceholder()}) {
    return GallerySubmissionList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<GallerySubmission>,
    );
  }
}

extension $GallerySubmissionListCopyWith on GallerySubmissionList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGallerySubmissionList.copyWith(...)` or `instanceOfGallerySubmissionList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GallerySubmissionListCWProxy get copyWith =>
      _$GallerySubmissionListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GallerySubmissionList _$GallerySubmissionListFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GallerySubmissionList', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = GallerySubmissionList(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => GallerySubmission.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$GallerySubmissionListToJson(
  GallerySubmissionList instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

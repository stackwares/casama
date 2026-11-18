// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_approval_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryApprovalListCWProxy {
  GalleryApprovalList items(List<GalleryApproval> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryApprovalList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryApprovalList(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryApprovalList call({List<GalleryApproval> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryApprovalList.copyWith(...)` or call `instanceOfGalleryApprovalList.copyWith.fieldName(value)` for a single field.
class _$GalleryApprovalListCWProxyImpl implements _$GalleryApprovalListCWProxy {
  const _$GalleryApprovalListCWProxyImpl(this._value);

  final GalleryApprovalList _value;

  @override
  GalleryApprovalList items(List<GalleryApproval> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryApprovalList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryApprovalList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryApprovalList call({Object? items = const $CopyWithPlaceholder()}) {
    return GalleryApprovalList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<GalleryApproval>,
    );
  }
}

extension $GalleryApprovalListCopyWith on GalleryApprovalList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryApprovalList.copyWith(...)` or `instanceOfGalleryApprovalList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryApprovalListCWProxy get copyWith =>
      _$GalleryApprovalListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryApprovalList _$GalleryApprovalListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryApprovalList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = GalleryApprovalList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => GalleryApproval.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GalleryApprovalListToJson(
  GalleryApprovalList instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

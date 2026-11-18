// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_gallery_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateGalleryRequestCWProxy {
  UpdateGalleryRequest status(UpdateGalleryRequestStatusEnum status);

  UpdateGalleryRequest doneItemKey(String? doneItemKey);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateGalleryRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateGalleryRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateGalleryRequest call({
    UpdateGalleryRequestStatusEnum status,
    String? doneItemKey,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateGalleryRequest.copyWith(...)` or call `instanceOfUpdateGalleryRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateGalleryRequestCWProxyImpl
    implements _$UpdateGalleryRequestCWProxy {
  const _$UpdateGalleryRequestCWProxyImpl(this._value);

  final UpdateGalleryRequest _value;

  @override
  UpdateGalleryRequest status(UpdateGalleryRequestStatusEnum status) =>
      call(status: status);

  @override
  UpdateGalleryRequest doneItemKey(String? doneItemKey) =>
      call(doneItemKey: doneItemKey);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateGalleryRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateGalleryRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateGalleryRequest call({
    Object? status = const $CopyWithPlaceholder(),
    Object? doneItemKey = const $CopyWithPlaceholder(),
  }) {
    return UpdateGalleryRequest(
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as UpdateGalleryRequestStatusEnum,
      doneItemKey: doneItemKey == const $CopyWithPlaceholder()
          ? _value.doneItemKey
          // ignore: cast_nullable_to_non_nullable
          : doneItemKey as String?,
    );
  }
}

extension $UpdateGalleryRequestCopyWith on UpdateGalleryRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateGalleryRequest.copyWith(...)` or `instanceOfUpdateGalleryRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateGalleryRequestCWProxy get copyWith =>
      _$UpdateGalleryRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateGalleryRequest _$UpdateGalleryRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UpdateGalleryRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['status']);
  final val = UpdateGalleryRequest(
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$UpdateGalleryRequestStatusEnumEnumMap, v),
    ),
    doneItemKey: $checkedConvert('done_item_key', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'doneItemKey': 'done_item_key'});

Map<String, dynamic> _$UpdateGalleryRequestToJson(
  UpdateGalleryRequest instance,
) => <String, dynamic>{
  'status': _$UpdateGalleryRequestStatusEnumEnumMap[instance.status]!,
  'done_item_key': ?instance.doneItemKey,
};

const _$UpdateGalleryRequestStatusEnumEnumMap = {
  UpdateGalleryRequestStatusEnum.open: 'open',
  UpdateGalleryRequestStatusEnum.planned: 'planned',
  UpdateGalleryRequestStatusEnum.done: 'done',
  UpdateGalleryRequestStatusEnum.declined: 'declined',
};

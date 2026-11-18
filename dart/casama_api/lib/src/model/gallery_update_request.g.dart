// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_update_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryUpdateRequestCWProxy {
  GalleryUpdateRequest orgId(String orgId);

  GalleryUpdateRequest type(GalleryWorkspaceKind type);

  GalleryUpdateRequest id(String id);

  GalleryUpdateRequest acceptAccess(bool? acceptAccess);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryUpdateRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryUpdateRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryUpdateRequest call({
    String orgId,
    GalleryWorkspaceKind type,
    String id,
    bool? acceptAccess,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryUpdateRequest.copyWith(...)` or call `instanceOfGalleryUpdateRequest.copyWith.fieldName(value)` for a single field.
class _$GalleryUpdateRequestCWProxyImpl
    implements _$GalleryUpdateRequestCWProxy {
  const _$GalleryUpdateRequestCWProxyImpl(this._value);

  final GalleryUpdateRequest _value;

  @override
  GalleryUpdateRequest orgId(String orgId) => call(orgId: orgId);

  @override
  GalleryUpdateRequest type(GalleryWorkspaceKind type) => call(type: type);

  @override
  GalleryUpdateRequest id(String id) => call(id: id);

  @override
  GalleryUpdateRequest acceptAccess(bool? acceptAccess) =>
      call(acceptAccess: acceptAccess);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryUpdateRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryUpdateRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryUpdateRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? acceptAccess = const $CopyWithPlaceholder(),
  }) {
    return GalleryUpdateRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as GalleryWorkspaceKind,
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      acceptAccess: acceptAccess == const $CopyWithPlaceholder()
          ? _value.acceptAccess
          // ignore: cast_nullable_to_non_nullable
          : acceptAccess as bool?,
    );
  }
}

extension $GalleryUpdateRequestCopyWith on GalleryUpdateRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryUpdateRequest.copyWith(...)` or `instanceOfGalleryUpdateRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryUpdateRequestCWProxy get copyWith =>
      _$GalleryUpdateRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryUpdateRequest _$GalleryUpdateRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GalleryUpdateRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['org_id', 'type', 'id']);
  final val = GalleryUpdateRequest(
    orgId: $checkedConvert('org_id', (v) => v as String),
    type: $checkedConvert(
      'type',
      (v) => $enumDecode(_$GalleryWorkspaceKindEnumMap, v),
    ),
    id: $checkedConvert('id', (v) => v as String),
    acceptAccess: $checkedConvert('accept_access', (v) => v as bool?),
  );
  return val;
}, fieldKeyMap: const {'orgId': 'org_id', 'acceptAccess': 'accept_access'});

Map<String, dynamic> _$GalleryUpdateRequestToJson(
  GalleryUpdateRequest instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'type': _$GalleryWorkspaceKindEnumMap[instance.type]!,
  'id': instance.id,
  'accept_access': ?instance.acceptAccess,
};

const _$GalleryWorkspaceKindEnumMap = {
  GalleryWorkspaceKind.skill: 'skill',
  GalleryWorkspaceKind.app: 'app',
  GalleryWorkspaceKind.bot: 'bot',
  GalleryWorkspaceKind.routine: 'routine',
  GalleryWorkspaceKind.plugin: 'plugin',
};

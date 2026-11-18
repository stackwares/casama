// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_install_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryInstallRequestCWProxy {
  GalleryInstallRequest orgId(String orgId);

  GalleryInstallRequest type(GalleryWorkspaceKind type);

  GalleryInstallRequest id(String id);

  GalleryInstallRequest inputs(Map<String, String>? inputs);

  GalleryInstallRequest botId(String? botId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryInstallRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryInstallRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryInstallRequest call({
    String orgId,
    GalleryWorkspaceKind type,
    String id,
    Map<String, String>? inputs,
    String? botId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryInstallRequest.copyWith(...)` or call `instanceOfGalleryInstallRequest.copyWith.fieldName(value)` for a single field.
class _$GalleryInstallRequestCWProxyImpl
    implements _$GalleryInstallRequestCWProxy {
  const _$GalleryInstallRequestCWProxyImpl(this._value);

  final GalleryInstallRequest _value;

  @override
  GalleryInstallRequest orgId(String orgId) => call(orgId: orgId);

  @override
  GalleryInstallRequest type(GalleryWorkspaceKind type) => call(type: type);

  @override
  GalleryInstallRequest id(String id) => call(id: id);

  @override
  GalleryInstallRequest inputs(Map<String, String>? inputs) =>
      call(inputs: inputs);

  @override
  GalleryInstallRequest botId(String? botId) => call(botId: botId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryInstallRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryInstallRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryInstallRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? inputs = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
  }) {
    return GalleryInstallRequest(
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
      inputs: inputs == const $CopyWithPlaceholder()
          ? _value.inputs
          // ignore: cast_nullable_to_non_nullable
          : inputs as Map<String, String>?,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String?,
    );
  }
}

extension $GalleryInstallRequestCopyWith on GalleryInstallRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryInstallRequest.copyWith(...)` or `instanceOfGalleryInstallRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryInstallRequestCWProxy get copyWith =>
      _$GalleryInstallRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryInstallRequest _$GalleryInstallRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GalleryInstallRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['org_id', 'type', 'id']);
  final val = GalleryInstallRequest(
    orgId: $checkedConvert('org_id', (v) => v as String),
    type: $checkedConvert(
      'type',
      (v) => $enumDecode(_$GalleryWorkspaceKindEnumMap, v),
    ),
    id: $checkedConvert('id', (v) => v as String),
    inputs: $checkedConvert(
      'inputs',
      (v) =>
          (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as String)),
    ),
    botId: $checkedConvert('bot_id', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'orgId': 'org_id', 'botId': 'bot_id'});

Map<String, dynamic> _$GalleryInstallRequestToJson(
  GalleryInstallRequest instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'type': _$GalleryWorkspaceKindEnumMap[instance.type]!,
  'id': instance.id,
  'inputs': ?instance.inputs,
  'bot_id': ?instance.botId,
};

const _$GalleryWorkspaceKindEnumMap = {
  GalleryWorkspaceKind.skill: 'skill',
  GalleryWorkspaceKind.app: 'app',
  GalleryWorkspaceKind.bot: 'bot',
  GalleryWorkspaceKind.routine: 'routine',
  GalleryWorkspaceKind.plugin: 'plugin',
};

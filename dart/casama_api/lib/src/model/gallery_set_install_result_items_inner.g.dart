// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_set_install_result_items_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GallerySetInstallResultItemsInnerCWProxy {
  GallerySetInstallResultItemsInner type(GalleryKind type);

  GallerySetInstallResultItemsInner id(String id);

  GallerySetInstallResultItemsInner status(
    GallerySetInstallResultItemsInnerStatusEnum status,
  );

  GallerySetInstallResultItemsInner installed(
    GalleryInstallResultInstalled? installed,
  );

  GallerySetInstallResultItemsInner error(String? error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GallerySetInstallResultItemsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GallerySetInstallResultItemsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  GallerySetInstallResultItemsInner call({
    GalleryKind type,
    String id,
    GallerySetInstallResultItemsInnerStatusEnum status,
    GalleryInstallResultInstalled? installed,
    String? error,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGallerySetInstallResultItemsInner.copyWith(...)` or call `instanceOfGallerySetInstallResultItemsInner.copyWith.fieldName(value)` for a single field.
class _$GallerySetInstallResultItemsInnerCWProxyImpl
    implements _$GallerySetInstallResultItemsInnerCWProxy {
  const _$GallerySetInstallResultItemsInnerCWProxyImpl(this._value);

  final GallerySetInstallResultItemsInner _value;

  @override
  GallerySetInstallResultItemsInner type(GalleryKind type) => call(type: type);

  @override
  GallerySetInstallResultItemsInner id(String id) => call(id: id);

  @override
  GallerySetInstallResultItemsInner status(
    GallerySetInstallResultItemsInnerStatusEnum status,
  ) => call(status: status);

  @override
  GallerySetInstallResultItemsInner installed(
    GalleryInstallResultInstalled? installed,
  ) => call(installed: installed);

  @override
  GallerySetInstallResultItemsInner error(String? error) => call(error: error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GallerySetInstallResultItemsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GallerySetInstallResultItemsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GallerySetInstallResultItemsInner call({
    Object? type = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? installed = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
  }) {
    return GallerySetInstallResultItemsInner(
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as GalleryKind,
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as GallerySetInstallResultItemsInnerStatusEnum,
      installed: installed == const $CopyWithPlaceholder()
          ? _value.installed
          // ignore: cast_nullable_to_non_nullable
          : installed as GalleryInstallResultInstalled?,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
    );
  }
}

extension $GallerySetInstallResultItemsInnerCopyWith
    on GallerySetInstallResultItemsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGallerySetInstallResultItemsInner.copyWith(...)` or `instanceOfGallerySetInstallResultItemsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GallerySetInstallResultItemsInnerCWProxy get copyWith =>
      _$GallerySetInstallResultItemsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GallerySetInstallResultItemsInner _$GallerySetInstallResultItemsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GallerySetInstallResultItemsInner', json, (
  $checkedConvert,
) {
  $checkKeys(
    json,
    requiredKeys: const ['type', 'id', 'status', 'installed', 'error'],
  );
  final val = GallerySetInstallResultItemsInner(
    type: $checkedConvert('type', (v) => $enumDecode(_$GalleryKindEnumMap, v)),
    id: $checkedConvert('id', (v) => v as String),
    status: $checkedConvert(
      'status',
      (v) =>
          $enumDecode(_$GallerySetInstallResultItemsInnerStatusEnumEnumMap, v),
    ),
    installed: $checkedConvert(
      'installed',
      (v) => v == null
          ? null
          : GalleryInstallResultInstalled.fromJson(v as Map<String, dynamic>),
    ),
    error: $checkedConvert('error', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$GallerySetInstallResultItemsInnerToJson(
  GallerySetInstallResultItemsInner instance,
) => <String, dynamic>{
  'type': _$GalleryKindEnumMap[instance.type]!,
  'id': instance.id,
  'status':
      _$GallerySetInstallResultItemsInnerStatusEnumEnumMap[instance.status]!,
  'installed': instance.installed?.toJson(),
  'error': instance.error,
};

const _$GalleryKindEnumMap = {
  GalleryKind.theme: 'theme',
  GalleryKind.scheme: 'scheme',
  GalleryKind.wallpaper: 'wallpaper',
  GalleryKind.skill: 'skill',
  GalleryKind.app: 'app',
  GalleryKind.bot: 'bot',
  GalleryKind.routine: 'routine',
  GalleryKind.plugin: 'plugin',
};

const _$GallerySetInstallResultItemsInnerStatusEnumEnumMap = {
  GallerySetInstallResultItemsInnerStatusEnum.installed: 'installed',
  GallerySetInstallResultItemsInnerStatusEnum.approvalPending:
      'approval_pending',
  GallerySetInstallResultItemsInnerStatusEnum.skipped: 'skipped',
  GallerySetInstallResultItemsInnerStatusEnum.failed: 'failed',
  GallerySetInstallResultItemsInnerStatusEnum.device: 'device',
};

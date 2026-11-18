// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_install_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryInstallResultCWProxy {
  GalleryInstallResult status(GalleryInstallResultStatusEnum status);

  GalleryInstallResult installed(GalleryInstallResultInstalled? installed);

  GalleryInstallResult approvalId(String? approvalId);

  GalleryInstallResult missing(GalleryMissing missing);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryInstallResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryInstallResult(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryInstallResult call({
    GalleryInstallResultStatusEnum status,
    GalleryInstallResultInstalled? installed,
    String? approvalId,
    GalleryMissing missing,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryInstallResult.copyWith(...)` or call `instanceOfGalleryInstallResult.copyWith.fieldName(value)` for a single field.
class _$GalleryInstallResultCWProxyImpl
    implements _$GalleryInstallResultCWProxy {
  const _$GalleryInstallResultCWProxyImpl(this._value);

  final GalleryInstallResult _value;

  @override
  GalleryInstallResult status(GalleryInstallResultStatusEnum status) =>
      call(status: status);

  @override
  GalleryInstallResult installed(GalleryInstallResultInstalled? installed) =>
      call(installed: installed);

  @override
  GalleryInstallResult approvalId(String? approvalId) =>
      call(approvalId: approvalId);

  @override
  GalleryInstallResult missing(GalleryMissing missing) =>
      call(missing: missing);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryInstallResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryInstallResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryInstallResult call({
    Object? status = const $CopyWithPlaceholder(),
    Object? installed = const $CopyWithPlaceholder(),
    Object? approvalId = const $CopyWithPlaceholder(),
    Object? missing = const $CopyWithPlaceholder(),
  }) {
    return GalleryInstallResult(
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as GalleryInstallResultStatusEnum,
      installed: installed == const $CopyWithPlaceholder()
          ? _value.installed
          // ignore: cast_nullable_to_non_nullable
          : installed as GalleryInstallResultInstalled?,
      approvalId: approvalId == const $CopyWithPlaceholder()
          ? _value.approvalId
          // ignore: cast_nullable_to_non_nullable
          : approvalId as String?,
      missing: missing == const $CopyWithPlaceholder() || missing == null
          ? _value.missing
          // ignore: cast_nullable_to_non_nullable
          : missing as GalleryMissing,
    );
  }
}

extension $GalleryInstallResultCopyWith on GalleryInstallResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryInstallResult.copyWith(...)` or `instanceOfGalleryInstallResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryInstallResultCWProxy get copyWith =>
      _$GalleryInstallResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryInstallResult _$GalleryInstallResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GalleryInstallResult', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['status', 'installed', 'approval_id', 'missing'],
  );
  final val = GalleryInstallResult(
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$GalleryInstallResultStatusEnumEnumMap, v),
    ),
    installed: $checkedConvert(
      'installed',
      (v) => v == null
          ? null
          : GalleryInstallResultInstalled.fromJson(v as Map<String, dynamic>),
    ),
    approvalId: $checkedConvert('approval_id', (v) => v as String?),
    missing: $checkedConvert(
      'missing',
      (v) => GalleryMissing.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
}, fieldKeyMap: const {'approvalId': 'approval_id'});

Map<String, dynamic> _$GalleryInstallResultToJson(
  GalleryInstallResult instance,
) => <String, dynamic>{
  'status': _$GalleryInstallResultStatusEnumEnumMap[instance.status]!,
  'installed': instance.installed?.toJson(),
  'approval_id': instance.approvalId,
  'missing': instance.missing.toJson(),
};

const _$GalleryInstallResultStatusEnumEnumMap = {
  GalleryInstallResultStatusEnum.installed: 'installed',
  GalleryInstallResultStatusEnum.approvalPending: 'approval_pending',
};

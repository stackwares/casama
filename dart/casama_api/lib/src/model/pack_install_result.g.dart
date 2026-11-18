// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_install_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackInstallResultCWProxy {
  PackInstallResult status(PackInstallResultStatusEnum status);

  PackInstallResult approvalId(String? approvalId);

  PackInstallResult pack(Pack? pack);

  PackInstallResult items(List<PackInstallItem> items);

  PackInstallResult missing(PackInstallResultMissing missing);

  PackInstallResult looks(List<PackLookPreview> looks);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackInstallResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackInstallResult(...).copyWith(id: 12, name: "My name")
  /// ```
  PackInstallResult call({
    PackInstallResultStatusEnum status,
    String? approvalId,
    Pack? pack,
    List<PackInstallItem> items,
    PackInstallResultMissing missing,
    List<PackLookPreview> looks,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackInstallResult.copyWith(...)` or call `instanceOfPackInstallResult.copyWith.fieldName(value)` for a single field.
class _$PackInstallResultCWProxyImpl implements _$PackInstallResultCWProxy {
  const _$PackInstallResultCWProxyImpl(this._value);

  final PackInstallResult _value;

  @override
  PackInstallResult status(PackInstallResultStatusEnum status) =>
      call(status: status);

  @override
  PackInstallResult approvalId(String? approvalId) =>
      call(approvalId: approvalId);

  @override
  PackInstallResult pack(Pack? pack) => call(pack: pack);

  @override
  PackInstallResult items(List<PackInstallItem> items) => call(items: items);

  @override
  PackInstallResult missing(PackInstallResultMissing missing) =>
      call(missing: missing);

  @override
  PackInstallResult looks(List<PackLookPreview> looks) => call(looks: looks);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackInstallResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackInstallResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackInstallResult call({
    Object? status = const $CopyWithPlaceholder(),
    Object? approvalId = const $CopyWithPlaceholder(),
    Object? pack = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? missing = const $CopyWithPlaceholder(),
    Object? looks = const $CopyWithPlaceholder(),
  }) {
    return PackInstallResult(
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as PackInstallResultStatusEnum,
      approvalId: approvalId == const $CopyWithPlaceholder()
          ? _value.approvalId
          // ignore: cast_nullable_to_non_nullable
          : approvalId as String?,
      pack: pack == const $CopyWithPlaceholder()
          ? _value.pack
          // ignore: cast_nullable_to_non_nullable
          : pack as Pack?,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<PackInstallItem>,
      missing: missing == const $CopyWithPlaceholder() || missing == null
          ? _value.missing
          // ignore: cast_nullable_to_non_nullable
          : missing as PackInstallResultMissing,
      looks: looks == const $CopyWithPlaceholder() || looks == null
          ? _value.looks
          // ignore: cast_nullable_to_non_nullable
          : looks as List<PackLookPreview>,
    );
  }
}

extension $PackInstallResultCopyWith on PackInstallResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackInstallResult.copyWith(...)` or `instanceOfPackInstallResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackInstallResultCWProxy get copyWith =>
      _$PackInstallResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackInstallResult _$PackInstallResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PackInstallResult', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'status',
          'approval_id',
          'items',
          'missing',
          'looks',
        ],
      );
      final val = PackInstallResult(
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$PackInstallResultStatusEnumEnumMap, v),
        ),
        approvalId: $checkedConvert('approval_id', (v) => v as String?),
        pack: $checkedConvert(
          'pack',
          (v) => v == null ? null : Pack.fromJson(v as Map<String, dynamic>),
        ),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => PackInstallItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        missing: $checkedConvert(
          'missing',
          (v) => PackInstallResultMissing.fromJson(v as Map<String, dynamic>),
        ),
        looks: $checkedConvert(
          'looks',
          (v) => (v as List<dynamic>)
              .map((e) => PackLookPreview.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'approvalId': 'approval_id'});

Map<String, dynamic> _$PackInstallResultToJson(PackInstallResult instance) =>
    <String, dynamic>{
      'status': _$PackInstallResultStatusEnumEnumMap[instance.status]!,
      'approval_id': instance.approvalId,
      'pack': ?instance.pack?.toJson(),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'missing': instance.missing.toJson(),
      'looks': instance.looks.map((e) => e.toJson()).toList(),
    };

const _$PackInstallResultStatusEnumEnumMap = {
  PackInstallResultStatusEnum.installed: 'installed',
  PackInstallResultStatusEnum.approvalPending: 'approval_pending',
};

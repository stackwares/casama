// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_reading.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VendorReadingCWProxy {
  VendorReading checkedAt(String checkedAt);

  VendorReading used(num? used);

  VendorReading remaining(num? remaining);

  VendorReading limitValue(num? limitValue);

  VendorReading resetsAt(String? resetsAt);

  VendorReading status(VendorReadingStatusEnum status);

  VendorReading source_(VendorReadingSource_Enum source_);

  VendorReading error(String? error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VendorReading(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VendorReading(...).copyWith(id: 12, name: "My name")
  /// ```
  VendorReading call({
    String checkedAt,
    num? used,
    num? remaining,
    num? limitValue,
    String? resetsAt,
    VendorReadingStatusEnum status,
    VendorReadingSource_Enum source_,
    String? error,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVendorReading.copyWith(...)` or call `instanceOfVendorReading.copyWith.fieldName(value)` for a single field.
class _$VendorReadingCWProxyImpl implements _$VendorReadingCWProxy {
  const _$VendorReadingCWProxyImpl(this._value);

  final VendorReading _value;

  @override
  VendorReading checkedAt(String checkedAt) => call(checkedAt: checkedAt);

  @override
  VendorReading used(num? used) => call(used: used);

  @override
  VendorReading remaining(num? remaining) => call(remaining: remaining);

  @override
  VendorReading limitValue(num? limitValue) => call(limitValue: limitValue);

  @override
  VendorReading resetsAt(String? resetsAt) => call(resetsAt: resetsAt);

  @override
  VendorReading status(VendorReadingStatusEnum status) => call(status: status);

  @override
  VendorReading source_(VendorReadingSource_Enum source_) =>
      call(source_: source_);

  @override
  VendorReading error(String? error) => call(error: error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VendorReading(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VendorReading(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VendorReading call({
    Object? checkedAt = const $CopyWithPlaceholder(),
    Object? used = const $CopyWithPlaceholder(),
    Object? remaining = const $CopyWithPlaceholder(),
    Object? limitValue = const $CopyWithPlaceholder(),
    Object? resetsAt = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
  }) {
    return VendorReading(
      checkedAt: checkedAt == const $CopyWithPlaceholder() || checkedAt == null
          ? _value.checkedAt
          // ignore: cast_nullable_to_non_nullable
          : checkedAt as String,
      used: used == const $CopyWithPlaceholder()
          ? _value.used
          // ignore: cast_nullable_to_non_nullable
          : used as num?,
      remaining: remaining == const $CopyWithPlaceholder()
          ? _value.remaining
          // ignore: cast_nullable_to_non_nullable
          : remaining as num?,
      limitValue: limitValue == const $CopyWithPlaceholder()
          ? _value.limitValue
          // ignore: cast_nullable_to_non_nullable
          : limitValue as num?,
      resetsAt: resetsAt == const $CopyWithPlaceholder()
          ? _value.resetsAt
          // ignore: cast_nullable_to_non_nullable
          : resetsAt as String?,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as VendorReadingStatusEnum,
      source_: source_ == const $CopyWithPlaceholder() || source_ == null
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as VendorReadingSource_Enum,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
    );
  }
}

extension $VendorReadingCopyWith on VendorReading {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVendorReading.copyWith(...)` or `instanceOfVendorReading.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VendorReadingCWProxy get copyWith => _$VendorReadingCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorReading _$VendorReadingFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'VendorReading',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'checked_at',
            'used',
            'remaining',
            'limit_value',
            'resets_at',
            'status',
            'source',
            'error',
          ],
        );
        final val = VendorReading(
          checkedAt: $checkedConvert('checked_at', (v) => v as String),
          used: $checkedConvert('used', (v) => v as num?),
          remaining: $checkedConvert('remaining', (v) => v as num?),
          limitValue: $checkedConvert('limit_value', (v) => v as num?),
          resetsAt: $checkedConvert('resets_at', (v) => v as String?),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$VendorReadingStatusEnumEnumMap, v),
          ),
          source_: $checkedConvert(
            'source',
            (v) => $enumDecode(_$VendorReadingSource_EnumEnumMap, v),
          ),
          error: $checkedConvert('error', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'checkedAt': 'checked_at',
        'limitValue': 'limit_value',
        'resetsAt': 'resets_at',
        'source_': 'source',
      },
    );

Map<String, dynamic> _$VendorReadingToJson(VendorReading instance) =>
    <String, dynamic>{
      'checked_at': instance.checkedAt,
      'used': instance.used,
      'remaining': instance.remaining,
      'limit_value': instance.limitValue,
      'resets_at': instance.resetsAt,
      'status': _$VendorReadingStatusEnumEnumMap[instance.status]!,
      'source': _$VendorReadingSource_EnumEnumMap[instance.source_]!,
      'error': instance.error,
    };

const _$VendorReadingStatusEnumEnumMap = {
  VendorReadingStatusEnum.ok: 'ok',
  VendorReadingStatusEnum.low: 'low',
  VendorReadingStatusEnum.out_: 'out',
  VendorReadingStatusEnum.unknown: 'unknown',
};

const _$VendorReadingSource_EnumEnumMap = {
  VendorReadingSource_Enum.api: 'api',
  VendorReadingSource_Enum.ownCount: 'own_count',
  VendorReadingSource_Enum.manual: 'manual',
};

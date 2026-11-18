// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_access.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryAccessCWProxy {
  GalleryAccess reads(List<String>? reads);

  GalleryAccess writes(List<String>? writes);

  GalleryAccess runsCode(bool? runsCode);

  GalleryAccess computer(bool? computer);

  GalleryAccess credits(GalleryAccessCreditsEnum? credits);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryAccess(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryAccess(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryAccess call({
    List<String>? reads,
    List<String>? writes,
    bool? runsCode,
    bool? computer,
    GalleryAccessCreditsEnum? credits,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryAccess.copyWith(...)` or call `instanceOfGalleryAccess.copyWith.fieldName(value)` for a single field.
class _$GalleryAccessCWProxyImpl implements _$GalleryAccessCWProxy {
  const _$GalleryAccessCWProxyImpl(this._value);

  final GalleryAccess _value;

  @override
  GalleryAccess reads(List<String>? reads) => call(reads: reads);

  @override
  GalleryAccess writes(List<String>? writes) => call(writes: writes);

  @override
  GalleryAccess runsCode(bool? runsCode) => call(runsCode: runsCode);

  @override
  GalleryAccess computer(bool? computer) => call(computer: computer);

  @override
  GalleryAccess credits(GalleryAccessCreditsEnum? credits) =>
      call(credits: credits);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryAccess(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryAccess(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryAccess call({
    Object? reads = const $CopyWithPlaceholder(),
    Object? writes = const $CopyWithPlaceholder(),
    Object? runsCode = const $CopyWithPlaceholder(),
    Object? computer = const $CopyWithPlaceholder(),
    Object? credits = const $CopyWithPlaceholder(),
  }) {
    return GalleryAccess(
      reads: reads == const $CopyWithPlaceholder()
          ? _value.reads
          // ignore: cast_nullable_to_non_nullable
          : reads as List<String>?,
      writes: writes == const $CopyWithPlaceholder()
          ? _value.writes
          // ignore: cast_nullable_to_non_nullable
          : writes as List<String>?,
      runsCode: runsCode == const $CopyWithPlaceholder()
          ? _value.runsCode
          // ignore: cast_nullable_to_non_nullable
          : runsCode as bool?,
      computer: computer == const $CopyWithPlaceholder()
          ? _value.computer
          // ignore: cast_nullable_to_non_nullable
          : computer as bool?,
      credits: credits == const $CopyWithPlaceholder()
          ? _value.credits
          // ignore: cast_nullable_to_non_nullable
          : credits as GalleryAccessCreditsEnum?,
    );
  }
}

extension $GalleryAccessCopyWith on GalleryAccess {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryAccess.copyWith(...)` or `instanceOfGalleryAccess.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryAccessCWProxy get copyWith => _$GalleryAccessCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryAccess _$GalleryAccessFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryAccess', json, ($checkedConvert) {
      final val = GalleryAccess(
        reads: $checkedConvert(
          'reads',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        writes: $checkedConvert(
          'writes',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        runsCode: $checkedConvert('runs_code', (v) => v as bool?),
        computer: $checkedConvert('computer', (v) => v as bool?),
        credits: $checkedConvert(
          'credits',
          (v) => $enumDecodeNullable(_$GalleryAccessCreditsEnumEnumMap, v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runsCode': 'runs_code'});

Map<String, dynamic> _$GalleryAccessToJson(GalleryAccess instance) =>
    <String, dynamic>{
      'reads': ?instance.reads,
      'writes': ?instance.writes,
      'runs_code': ?instance.runsCode,
      'computer': ?instance.computer,
      'credits': ?_$GalleryAccessCreditsEnumEnumMap[instance.credits],
    };

const _$GalleryAccessCreditsEnumEnumMap = {
  GalleryAccessCreditsEnum.none: 'none',
  GalleryAccessCreditsEnum.low: 'low',
  GalleryAccessCreditsEnum.medium: 'medium',
  GalleryAccessCreditsEnum.high: 'high',
};

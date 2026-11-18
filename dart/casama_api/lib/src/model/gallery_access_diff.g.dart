// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_access_diff.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryAccessDiffCWProxy {
  GalleryAccessDiff reads(List<String> reads);

  GalleryAccessDiff writes(List<String> writes);

  GalleryAccessDiff runsCode(bool runsCode);

  GalleryAccessDiff computer(bool computer);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryAccessDiff(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryAccessDiff(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryAccessDiff call({
    List<String> reads,
    List<String> writes,
    bool runsCode,
    bool computer,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryAccessDiff.copyWith(...)` or call `instanceOfGalleryAccessDiff.copyWith.fieldName(value)` for a single field.
class _$GalleryAccessDiffCWProxyImpl implements _$GalleryAccessDiffCWProxy {
  const _$GalleryAccessDiffCWProxyImpl(this._value);

  final GalleryAccessDiff _value;

  @override
  GalleryAccessDiff reads(List<String> reads) => call(reads: reads);

  @override
  GalleryAccessDiff writes(List<String> writes) => call(writes: writes);

  @override
  GalleryAccessDiff runsCode(bool runsCode) => call(runsCode: runsCode);

  @override
  GalleryAccessDiff computer(bool computer) => call(computer: computer);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryAccessDiff(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryAccessDiff(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryAccessDiff call({
    Object? reads = const $CopyWithPlaceholder(),
    Object? writes = const $CopyWithPlaceholder(),
    Object? runsCode = const $CopyWithPlaceholder(),
    Object? computer = const $CopyWithPlaceholder(),
  }) {
    return GalleryAccessDiff(
      reads: reads == const $CopyWithPlaceholder() || reads == null
          ? _value.reads
          // ignore: cast_nullable_to_non_nullable
          : reads as List<String>,
      writes: writes == const $CopyWithPlaceholder() || writes == null
          ? _value.writes
          // ignore: cast_nullable_to_non_nullable
          : writes as List<String>,
      runsCode: runsCode == const $CopyWithPlaceholder() || runsCode == null
          ? _value.runsCode
          // ignore: cast_nullable_to_non_nullable
          : runsCode as bool,
      computer: computer == const $CopyWithPlaceholder() || computer == null
          ? _value.computer
          // ignore: cast_nullable_to_non_nullable
          : computer as bool,
    );
  }
}

extension $GalleryAccessDiffCopyWith on GalleryAccessDiff {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryAccessDiff.copyWith(...)` or `instanceOfGalleryAccessDiff.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryAccessDiffCWProxy get copyWith =>
      _$GalleryAccessDiffCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryAccessDiff _$GalleryAccessDiffFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryAccessDiff', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['reads', 'writes', 'runs_code', 'computer'],
      );
      final val = GalleryAccessDiff(
        reads: $checkedConvert(
          'reads',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        writes: $checkedConvert(
          'writes',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        runsCode: $checkedConvert('runs_code', (v) => v as bool),
        computer: $checkedConvert('computer', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'runsCode': 'runs_code'});

Map<String, dynamic> _$GalleryAccessDiffToJson(GalleryAccessDiff instance) =>
    <String, dynamic>{
      'reads': instance.reads,
      'writes': instance.writes,
      'runs_code': instance.runsCode,
      'computer': instance.computer,
    };

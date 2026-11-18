// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_change.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryChangeCWProxy {
  GalleryChange version(int version);

  GalleryChange date(String date);

  GalleryChange note(String note);

  GalleryChange breaking(bool? breaking);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryChange(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryChange(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryChange call({int version, String date, String note, bool? breaking});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryChange.copyWith(...)` or call `instanceOfGalleryChange.copyWith.fieldName(value)` for a single field.
class _$GalleryChangeCWProxyImpl implements _$GalleryChangeCWProxy {
  const _$GalleryChangeCWProxyImpl(this._value);

  final GalleryChange _value;

  @override
  GalleryChange version(int version) => call(version: version);

  @override
  GalleryChange date(String date) => call(date: date);

  @override
  GalleryChange note(String note) => call(note: note);

  @override
  GalleryChange breaking(bool? breaking) => call(breaking: breaking);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryChange(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryChange(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryChange call({
    Object? version = const $CopyWithPlaceholder(),
    Object? date = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? breaking = const $CopyWithPlaceholder(),
  }) {
    return GalleryChange(
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
      date: date == const $CopyWithPlaceholder() || date == null
          ? _value.date
          // ignore: cast_nullable_to_non_nullable
          : date as String,
      note: note == const $CopyWithPlaceholder() || note == null
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String,
      breaking: breaking == const $CopyWithPlaceholder()
          ? _value.breaking
          // ignore: cast_nullable_to_non_nullable
          : breaking as bool?,
    );
  }
}

extension $GalleryChangeCopyWith on GalleryChange {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryChange.copyWith(...)` or `instanceOfGalleryChange.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryChangeCWProxy get copyWith => _$GalleryChangeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryChange _$GalleryChangeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryChange', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['version', 'date', 'note']);
      final val = GalleryChange(
        version: $checkedConvert('version', (v) => (v as num).toInt()),
        date: $checkedConvert('date', (v) => v as String),
        note: $checkedConvert('note', (v) => v as String),
        breaking: $checkedConvert('breaking', (v) => v as bool?),
      );
      return val;
    });

Map<String, dynamic> _$GalleryChangeToJson(GalleryChange instance) =>
    <String, dynamic>{
      'version': instance.version,
      'date': instance.date,
      'note': instance.note,
      'breaking': ?instance.breaking,
    };

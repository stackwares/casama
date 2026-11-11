// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_count.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SavedCountCWProxy {
  SavedCount saved(int saved);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SavedCount(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SavedCount(...).copyWith(id: 12, name: "My name")
  /// ```
  SavedCount call({int saved});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSavedCount.copyWith(...)` or call `instanceOfSavedCount.copyWith.fieldName(value)` for a single field.
class _$SavedCountCWProxyImpl implements _$SavedCountCWProxy {
  const _$SavedCountCWProxyImpl(this._value);

  final SavedCount _value;

  @override
  SavedCount saved(int saved) => call(saved: saved);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SavedCount(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SavedCount(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SavedCount call({Object? saved = const $CopyWithPlaceholder()}) {
    return SavedCount(
      saved: saved == const $CopyWithPlaceholder() || saved == null
          ? _value.saved
          // ignore: cast_nullable_to_non_nullable
          : saved as int,
    );
  }
}

extension $SavedCountCopyWith on SavedCount {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSavedCount.copyWith(...)` or `instanceOfSavedCount.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SavedCountCWProxy get copyWith => _$SavedCountCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SavedCount _$SavedCountFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SavedCount', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['saved']);
      final val = SavedCount(
        saved: $checkedConvert('saved', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$SavedCountToJson(SavedCount instance) =>
    <String, dynamic>{'saved': instance.saved};

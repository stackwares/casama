// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_turns.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SavedTurnsCWProxy {
  SavedTurns saved(int saved);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SavedTurns(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SavedTurns(...).copyWith(id: 12, name: "My name")
  /// ```
  SavedTurns call({int saved});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSavedTurns.copyWith(...)` or call `instanceOfSavedTurns.copyWith.fieldName(value)` for a single field.
class _$SavedTurnsCWProxyImpl implements _$SavedTurnsCWProxy {
  const _$SavedTurnsCWProxyImpl(this._value);

  final SavedTurns _value;

  @override
  SavedTurns saved(int saved) => call(saved: saved);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SavedTurns(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SavedTurns(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SavedTurns call({Object? saved = const $CopyWithPlaceholder()}) {
    return SavedTurns(
      saved: saved == const $CopyWithPlaceholder() || saved == null
          ? _value.saved
          // ignore: cast_nullable_to_non_nullable
          : saved as int,
    );
  }
}

extension $SavedTurnsCopyWith on SavedTurns {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSavedTurns.copyWith(...)` or `instanceOfSavedTurns.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SavedTurnsCWProxy get copyWith => _$SavedTurnsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SavedTurns _$SavedTurnsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SavedTurns', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['saved']);
      final val = SavedTurns(
        saved: $checkedConvert('saved', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$SavedTurnsToJson(SavedTurns instance) =>
    <String, dynamic>{'saved': instance.saved};

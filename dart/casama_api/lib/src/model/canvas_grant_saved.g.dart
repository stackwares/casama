// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_grant_saved.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CanvasGrantSavedCWProxy {
  CanvasGrantSaved allowed(bool allowed);

  CanvasGrantSaved shown(int shown);

  CanvasGrantSaved cleared(int cleared);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasGrantSaved(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasGrantSaved(...).copyWith(id: 12, name: "My name")
  /// ```
  CanvasGrantSaved call({bool allowed, int shown, int cleared});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCanvasGrantSaved.copyWith(...)` or call `instanceOfCanvasGrantSaved.copyWith.fieldName(value)` for a single field.
class _$CanvasGrantSavedCWProxyImpl implements _$CanvasGrantSavedCWProxy {
  const _$CanvasGrantSavedCWProxyImpl(this._value);

  final CanvasGrantSaved _value;

  @override
  CanvasGrantSaved allowed(bool allowed) => call(allowed: allowed);

  @override
  CanvasGrantSaved shown(int shown) => call(shown: shown);

  @override
  CanvasGrantSaved cleared(int cleared) => call(cleared: cleared);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasGrantSaved(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasGrantSaved(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CanvasGrantSaved call({
    Object? allowed = const $CopyWithPlaceholder(),
    Object? shown = const $CopyWithPlaceholder(),
    Object? cleared = const $CopyWithPlaceholder(),
  }) {
    return CanvasGrantSaved(
      allowed: allowed == const $CopyWithPlaceholder() || allowed == null
          ? _value.allowed
          // ignore: cast_nullable_to_non_nullable
          : allowed as bool,
      shown: shown == const $CopyWithPlaceholder() || shown == null
          ? _value.shown
          // ignore: cast_nullable_to_non_nullable
          : shown as int,
      cleared: cleared == const $CopyWithPlaceholder() || cleared == null
          ? _value.cleared
          // ignore: cast_nullable_to_non_nullable
          : cleared as int,
    );
  }
}

extension $CanvasGrantSavedCopyWith on CanvasGrantSaved {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCanvasGrantSaved.copyWith(...)` or `instanceOfCanvasGrantSaved.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CanvasGrantSavedCWProxy get copyWith => _$CanvasGrantSavedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanvasGrantSaved _$CanvasGrantSavedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CanvasGrantSaved', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['allowed', 'shown', 'cleared']);
      final val = CanvasGrantSaved(
        allowed: $checkedConvert('allowed', (v) => v as bool),
        shown: $checkedConvert('shown', (v) => (v as num).toInt()),
        cleared: $checkedConvert('cleared', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$CanvasGrantSavedToJson(CanvasGrantSaved instance) =>
    <String, dynamic>{
      'allowed': instance.allowed,
      'shown': instance.shown,
      'cleared': instance.cleared,
    };

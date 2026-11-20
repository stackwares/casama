// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_rotation.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CanvasRotationCWProxy {
  CanvasRotation count(int count);

  CanvasRotation showing(int showing);

  CanvasRotation left(int left);

  CanvasRotation every(String every);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasRotation(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasRotation(...).copyWith(id: 12, name: "My name")
  /// ```
  CanvasRotation call({int count, int showing, int left, String every});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCanvasRotation.copyWith(...)` or call `instanceOfCanvasRotation.copyWith.fieldName(value)` for a single field.
class _$CanvasRotationCWProxyImpl implements _$CanvasRotationCWProxy {
  const _$CanvasRotationCWProxyImpl(this._value);

  final CanvasRotation _value;

  @override
  CanvasRotation count(int count) => call(count: count);

  @override
  CanvasRotation showing(int showing) => call(showing: showing);

  @override
  CanvasRotation left(int left) => call(left: left);

  @override
  CanvasRotation every(String every) => call(every: every);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasRotation(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasRotation(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CanvasRotation call({
    Object? count = const $CopyWithPlaceholder(),
    Object? showing = const $CopyWithPlaceholder(),
    Object? left = const $CopyWithPlaceholder(),
    Object? every = const $CopyWithPlaceholder(),
  }) {
    return CanvasRotation(
      count: count == const $CopyWithPlaceholder() || count == null
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int,
      showing: showing == const $CopyWithPlaceholder() || showing == null
          ? _value.showing
          // ignore: cast_nullable_to_non_nullable
          : showing as int,
      left: left == const $CopyWithPlaceholder() || left == null
          ? _value.left
          // ignore: cast_nullable_to_non_nullable
          : left as int,
      every: every == const $CopyWithPlaceholder() || every == null
          ? _value.every
          // ignore: cast_nullable_to_non_nullable
          : every as String,
    );
  }
}

extension $CanvasRotationCopyWith on CanvasRotation {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCanvasRotation.copyWith(...)` or `instanceOfCanvasRotation.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CanvasRotationCWProxy get copyWith => _$CanvasRotationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanvasRotation _$CanvasRotationFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CanvasRotation', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['count', 'showing', 'left', 'every'],
      );
      final val = CanvasRotation(
        count: $checkedConvert('count', (v) => (v as num).toInt()),
        showing: $checkedConvert('showing', (v) => (v as num).toInt()),
        left: $checkedConvert('left', (v) => (v as num).toInt()),
        every: $checkedConvert('every', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$CanvasRotationToJson(CanvasRotation instance) =>
    <String, dynamic>{
      'count': instance.count,
      'showing': instance.showing,
      'left': instance.left,
      'every': instance.every,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_update.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CanvasUpdateCWProxy {
  CanvasUpdate status(CanvasUpdateStatusEnum? status);

  CanvasUpdate hideWhenLocked(bool? hideWhenLocked);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasUpdate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasUpdate(...).copyWith(id: 12, name: "My name")
  /// ```
  CanvasUpdate call({CanvasUpdateStatusEnum? status, bool? hideWhenLocked});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCanvasUpdate.copyWith(...)` or call `instanceOfCanvasUpdate.copyWith.fieldName(value)` for a single field.
class _$CanvasUpdateCWProxyImpl implements _$CanvasUpdateCWProxy {
  const _$CanvasUpdateCWProxyImpl(this._value);

  final CanvasUpdate _value;

  @override
  CanvasUpdate status(CanvasUpdateStatusEnum? status) => call(status: status);

  @override
  CanvasUpdate hideWhenLocked(bool? hideWhenLocked) =>
      call(hideWhenLocked: hideWhenLocked);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasUpdate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasUpdate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CanvasUpdate call({
    Object? status = const $CopyWithPlaceholder(),
    Object? hideWhenLocked = const $CopyWithPlaceholder(),
  }) {
    return CanvasUpdate(
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as CanvasUpdateStatusEnum?,
      hideWhenLocked: hideWhenLocked == const $CopyWithPlaceholder()
          ? _value.hideWhenLocked
          // ignore: cast_nullable_to_non_nullable
          : hideWhenLocked as bool?,
    );
  }
}

extension $CanvasUpdateCopyWith on CanvasUpdate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCanvasUpdate.copyWith(...)` or `instanceOfCanvasUpdate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CanvasUpdateCWProxy get copyWith => _$CanvasUpdateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanvasUpdate _$CanvasUpdateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CanvasUpdate', json, ($checkedConvert) {
      final val = CanvasUpdate(
        status: $checkedConvert(
          'status',
          (v) => $enumDecodeNullable(_$CanvasUpdateStatusEnumEnumMap, v),
        ),
        hideWhenLocked: $checkedConvert('hide_when_locked', (v) => v as bool?),
      );
      return val;
    }, fieldKeyMap: const {'hideWhenLocked': 'hide_when_locked'});

Map<String, dynamic> _$CanvasUpdateToJson(CanvasUpdate instance) =>
    <String, dynamic>{
      'status': ?_$CanvasUpdateStatusEnumEnumMap[instance.status],
      'hide_when_locked': ?instance.hideWhenLocked,
    };

const _$CanvasUpdateStatusEnumEnumMap = {
  CanvasUpdateStatusEnum.shown: 'shown',
  CanvasUpdateStatusEnum.paused: 'paused',
};

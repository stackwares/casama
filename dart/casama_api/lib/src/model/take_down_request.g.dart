// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'take_down_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TakeDownRequestCWProxy {
  TakeDownRequest down(bool down);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TakeDownRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TakeDownRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  TakeDownRequest call({bool down});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTakeDownRequest.copyWith(...)` or call `instanceOfTakeDownRequest.copyWith.fieldName(value)` for a single field.
class _$TakeDownRequestCWProxyImpl implements _$TakeDownRequestCWProxy {
  const _$TakeDownRequestCWProxyImpl(this._value);

  final TakeDownRequest _value;

  @override
  TakeDownRequest down(bool down) => call(down: down);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TakeDownRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TakeDownRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TakeDownRequest call({Object? down = const $CopyWithPlaceholder()}) {
    return TakeDownRequest(
      down: down == const $CopyWithPlaceholder() || down == null
          ? _value.down
          // ignore: cast_nullable_to_non_nullable
          : down as bool,
    );
  }
}

extension $TakeDownRequestCopyWith on TakeDownRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTakeDownRequest.copyWith(...)` or `instanceOfTakeDownRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TakeDownRequestCWProxy get copyWith => _$TakeDownRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TakeDownRequest _$TakeDownRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TakeDownRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['down']);
      final val = TakeDownRequest(
        down: $checkedConvert('down', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$TakeDownRequestToJson(TakeDownRequest instance) =>
    <String, dynamic>{'down': instance.down};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'take_over_call_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TakeOverCallRequestCWProxy {
  TakeOverCallRequest phone(String? phone);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TakeOverCallRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TakeOverCallRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  TakeOverCallRequest call({String? phone});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTakeOverCallRequest.copyWith(...)` or call `instanceOfTakeOverCallRequest.copyWith.fieldName(value)` for a single field.
class _$TakeOverCallRequestCWProxyImpl implements _$TakeOverCallRequestCWProxy {
  const _$TakeOverCallRequestCWProxyImpl(this._value);

  final TakeOverCallRequest _value;

  @override
  TakeOverCallRequest phone(String? phone) => call(phone: phone);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TakeOverCallRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TakeOverCallRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TakeOverCallRequest call({Object? phone = const $CopyWithPlaceholder()}) {
    return TakeOverCallRequest(
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String?,
    );
  }
}

extension $TakeOverCallRequestCopyWith on TakeOverCallRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTakeOverCallRequest.copyWith(...)` or `instanceOfTakeOverCallRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TakeOverCallRequestCWProxy get copyWith =>
      _$TakeOverCallRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TakeOverCallRequest _$TakeOverCallRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TakeOverCallRequest', json, ($checkedConvert) {
      final val = TakeOverCallRequest(
        phone: $checkedConvert('phone', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$TakeOverCallRequestToJson(
  TakeOverCallRequest instance,
) => <String, dynamic>{'phone': ?instance.phone};

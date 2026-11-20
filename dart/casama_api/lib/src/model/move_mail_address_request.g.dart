// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'move_mail_address_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MoveMailAddressRequestCWProxy {
  MoveMailAddressRequest toBotId(String toBotId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MoveMailAddressRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MoveMailAddressRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  MoveMailAddressRequest call({String toBotId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMoveMailAddressRequest.copyWith(...)` or call `instanceOfMoveMailAddressRequest.copyWith.fieldName(value)` for a single field.
class _$MoveMailAddressRequestCWProxyImpl
    implements _$MoveMailAddressRequestCWProxy {
  const _$MoveMailAddressRequestCWProxyImpl(this._value);

  final MoveMailAddressRequest _value;

  @override
  MoveMailAddressRequest toBotId(String toBotId) => call(toBotId: toBotId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MoveMailAddressRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MoveMailAddressRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MoveMailAddressRequest call({
    Object? toBotId = const $CopyWithPlaceholder(),
  }) {
    return MoveMailAddressRequest(
      toBotId: toBotId == const $CopyWithPlaceholder() || toBotId == null
          ? _value.toBotId
          // ignore: cast_nullable_to_non_nullable
          : toBotId as String,
    );
  }
}

extension $MoveMailAddressRequestCopyWith on MoveMailAddressRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMoveMailAddressRequest.copyWith(...)` or `instanceOfMoveMailAddressRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MoveMailAddressRequestCWProxy get copyWith =>
      _$MoveMailAddressRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoveMailAddressRequest _$MoveMailAddressRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('MoveMailAddressRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['to_bot_id']);
  final val = MoveMailAddressRequest(
    toBotId: $checkedConvert('to_bot_id', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'toBotId': 'to_bot_id'});

Map<String, dynamic> _$MoveMailAddressRequestToJson(
  MoveMailAddressRequest instance,
) => <String, dynamic>{'to_bot_id': instance.toBotId};

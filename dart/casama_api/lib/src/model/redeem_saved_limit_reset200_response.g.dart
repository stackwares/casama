// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redeem_saved_limit_reset200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RedeemSavedLimitReset200ResponseCWProxy {
  RedeemSavedLimitReset200Response resetId(String resetId);

  RedeemSavedLimitReset200Response refilledUsd(num refilledUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RedeemSavedLimitReset200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RedeemSavedLimitReset200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  RedeemSavedLimitReset200Response call({String resetId, num refilledUsd});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRedeemSavedLimitReset200Response.copyWith(...)` or call `instanceOfRedeemSavedLimitReset200Response.copyWith.fieldName(value)` for a single field.
class _$RedeemSavedLimitReset200ResponseCWProxyImpl
    implements _$RedeemSavedLimitReset200ResponseCWProxy {
  const _$RedeemSavedLimitReset200ResponseCWProxyImpl(this._value);

  final RedeemSavedLimitReset200Response _value;

  @override
  RedeemSavedLimitReset200Response resetId(String resetId) =>
      call(resetId: resetId);

  @override
  RedeemSavedLimitReset200Response refilledUsd(num refilledUsd) =>
      call(refilledUsd: refilledUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RedeemSavedLimitReset200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RedeemSavedLimitReset200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RedeemSavedLimitReset200Response call({
    Object? resetId = const $CopyWithPlaceholder(),
    Object? refilledUsd = const $CopyWithPlaceholder(),
  }) {
    return RedeemSavedLimitReset200Response(
      resetId: resetId == const $CopyWithPlaceholder() || resetId == null
          ? _value.resetId
          // ignore: cast_nullable_to_non_nullable
          : resetId as String,
      refilledUsd:
          refilledUsd == const $CopyWithPlaceholder() || refilledUsd == null
          ? _value.refilledUsd
          // ignore: cast_nullable_to_non_nullable
          : refilledUsd as num,
    );
  }
}

extension $RedeemSavedLimitReset200ResponseCopyWith
    on RedeemSavedLimitReset200Response {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRedeemSavedLimitReset200Response.copyWith(...)` or `instanceOfRedeemSavedLimitReset200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RedeemSavedLimitReset200ResponseCWProxy get copyWith =>
      _$RedeemSavedLimitReset200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RedeemSavedLimitReset200Response _$RedeemSavedLimitReset200ResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RedeemSavedLimitReset200Response', json, (
  $checkedConvert,
) {
  $checkKeys(json, requiredKeys: const ['reset_id', 'refilled_usd']);
  final val = RedeemSavedLimitReset200Response(
    resetId: $checkedConvert('reset_id', (v) => v as String),
    refilledUsd: $checkedConvert('refilled_usd', (v) => v as num),
  );
  return val;
}, fieldKeyMap: const {'resetId': 'reset_id', 'refilledUsd': 'refilled_usd'});

Map<String, dynamic> _$RedeemSavedLimitReset200ResponseToJson(
  RedeemSavedLimitReset200Response instance,
) => <String, dynamic>{
  'reset_id': instance.resetId,
  'refilled_usd': instance.refilledUsd,
};

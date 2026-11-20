// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redeem_comp_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RedeemCompRequestCWProxy {
  RedeemCompRequest code(String code);

  RedeemCompRequest orgId(String orgId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RedeemCompRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RedeemCompRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  RedeemCompRequest call({String code, String orgId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRedeemCompRequest.copyWith(...)` or call `instanceOfRedeemCompRequest.copyWith.fieldName(value)` for a single field.
class _$RedeemCompRequestCWProxyImpl implements _$RedeemCompRequestCWProxy {
  const _$RedeemCompRequestCWProxyImpl(this._value);

  final RedeemCompRequest _value;

  @override
  RedeemCompRequest code(String code) => call(code: code);

  @override
  RedeemCompRequest orgId(String orgId) => call(orgId: orgId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RedeemCompRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RedeemCompRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RedeemCompRequest call({
    Object? code = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
  }) {
    return RedeemCompRequest(
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
    );
  }
}

extension $RedeemCompRequestCopyWith on RedeemCompRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRedeemCompRequest.copyWith(...)` or `instanceOfRedeemCompRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RedeemCompRequestCWProxy get copyWith =>
      _$RedeemCompRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RedeemCompRequest _$RedeemCompRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RedeemCompRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['code', 'org_id']);
      final val = RedeemCompRequest(
        code: $checkedConvert('code', (v) => v as String),
        orgId: $checkedConvert('org_id', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'orgId': 'org_id'});

Map<String, dynamic> _$RedeemCompRequestToJson(RedeemCompRequest instance) =>
    <String, dynamic>{'code': instance.code, 'org_id': instance.orgId};

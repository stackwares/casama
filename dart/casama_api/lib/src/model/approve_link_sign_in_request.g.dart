// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approve_link_sign_in_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ApproveLinkSignInRequestCWProxy {
  ApproveLinkSignInRequest userCode(String userCode);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ApproveLinkSignInRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ApproveLinkSignInRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ApproveLinkSignInRequest call({String userCode});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfApproveLinkSignInRequest.copyWith(...)` or call `instanceOfApproveLinkSignInRequest.copyWith.fieldName(value)` for a single field.
class _$ApproveLinkSignInRequestCWProxyImpl
    implements _$ApproveLinkSignInRequestCWProxy {
  const _$ApproveLinkSignInRequestCWProxyImpl(this._value);

  final ApproveLinkSignInRequest _value;

  @override
  ApproveLinkSignInRequest userCode(String userCode) =>
      call(userCode: userCode);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ApproveLinkSignInRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ApproveLinkSignInRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ApproveLinkSignInRequest call({
    Object? userCode = const $CopyWithPlaceholder(),
  }) {
    return ApproveLinkSignInRequest(
      userCode: userCode == const $CopyWithPlaceholder() || userCode == null
          ? _value.userCode
          // ignore: cast_nullable_to_non_nullable
          : userCode as String,
    );
  }
}

extension $ApproveLinkSignInRequestCopyWith on ApproveLinkSignInRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfApproveLinkSignInRequest.copyWith(...)` or `instanceOfApproveLinkSignInRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ApproveLinkSignInRequestCWProxy get copyWith =>
      _$ApproveLinkSignInRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApproveLinkSignInRequest _$ApproveLinkSignInRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ApproveLinkSignInRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['user_code']);
  final val = ApproveLinkSignInRequest(
    userCode: $checkedConvert('user_code', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'userCode': 'user_code'});

Map<String, dynamic> _$ApproveLinkSignInRequestToJson(
  ApproveLinkSignInRequest instance,
) => <String, dynamic>{'user_code': instance.userCode};

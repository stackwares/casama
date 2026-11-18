// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approved_link_sign_in.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ApprovedLinkSignInCWProxy {
  ApprovedLinkSignIn instanceName(String instanceName);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ApprovedLinkSignIn(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ApprovedLinkSignIn(...).copyWith(id: 12, name: "My name")
  /// ```
  ApprovedLinkSignIn call({String instanceName});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfApprovedLinkSignIn.copyWith(...)` or call `instanceOfApprovedLinkSignIn.copyWith.fieldName(value)` for a single field.
class _$ApprovedLinkSignInCWProxyImpl implements _$ApprovedLinkSignInCWProxy {
  const _$ApprovedLinkSignInCWProxyImpl(this._value);

  final ApprovedLinkSignIn _value;

  @override
  ApprovedLinkSignIn instanceName(String instanceName) =>
      call(instanceName: instanceName);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ApprovedLinkSignIn(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ApprovedLinkSignIn(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ApprovedLinkSignIn call({
    Object? instanceName = const $CopyWithPlaceholder(),
  }) {
    return ApprovedLinkSignIn(
      instanceName:
          instanceName == const $CopyWithPlaceholder() || instanceName == null
          ? _value.instanceName
          // ignore: cast_nullable_to_non_nullable
          : instanceName as String,
    );
  }
}

extension $ApprovedLinkSignInCopyWith on ApprovedLinkSignIn {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfApprovedLinkSignIn.copyWith(...)` or `instanceOfApprovedLinkSignIn.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ApprovedLinkSignInCWProxy get copyWith =>
      _$ApprovedLinkSignInCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApprovedLinkSignIn _$ApprovedLinkSignInFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ApprovedLinkSignIn', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['instance_name']);
      final val = ApprovedLinkSignIn(
        instanceName: $checkedConvert('instance_name', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'instanceName': 'instance_name'});

Map<String, dynamic> _$ApprovedLinkSignInToJson(ApprovedLinkSignIn instance) =>
    <String, dynamic>{'instance_name': instance.instanceName};

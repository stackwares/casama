// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_password_manager_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdatePasswordManagerRequestCWProxy {
  UpdatePasswordManagerRequest allowedVaults(List<String> allowedVaults);

  UpdatePasswordManagerRequest allowedBotIds(List<String>? allowedBotIds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdatePasswordManagerRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdatePasswordManagerRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdatePasswordManagerRequest call({
    List<String> allowedVaults,
    List<String>? allowedBotIds,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdatePasswordManagerRequest.copyWith(...)` or call `instanceOfUpdatePasswordManagerRequest.copyWith.fieldName(value)` for a single field.
class _$UpdatePasswordManagerRequestCWProxyImpl
    implements _$UpdatePasswordManagerRequestCWProxy {
  const _$UpdatePasswordManagerRequestCWProxyImpl(this._value);

  final UpdatePasswordManagerRequest _value;

  @override
  UpdatePasswordManagerRequest allowedVaults(List<String> allowedVaults) =>
      call(allowedVaults: allowedVaults);

  @override
  UpdatePasswordManagerRequest allowedBotIds(List<String>? allowedBotIds) =>
      call(allowedBotIds: allowedBotIds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdatePasswordManagerRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdatePasswordManagerRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdatePasswordManagerRequest call({
    Object? allowedVaults = const $CopyWithPlaceholder(),
    Object? allowedBotIds = const $CopyWithPlaceholder(),
  }) {
    return UpdatePasswordManagerRequest(
      allowedVaults:
          allowedVaults == const $CopyWithPlaceholder() || allowedVaults == null
          ? _value.allowedVaults
          // ignore: cast_nullable_to_non_nullable
          : allowedVaults as List<String>,
      allowedBotIds: allowedBotIds == const $CopyWithPlaceholder()
          ? _value.allowedBotIds
          // ignore: cast_nullable_to_non_nullable
          : allowedBotIds as List<String>?,
    );
  }
}

extension $UpdatePasswordManagerRequestCopyWith
    on UpdatePasswordManagerRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdatePasswordManagerRequest.copyWith(...)` or `instanceOfUpdatePasswordManagerRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdatePasswordManagerRequestCWProxy get copyWith =>
      _$UpdatePasswordManagerRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdatePasswordManagerRequest _$UpdatePasswordManagerRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'UpdatePasswordManagerRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['allowed_vaults']);
    final val = UpdatePasswordManagerRequest(
      allowedVaults: $checkedConvert(
        'allowed_vaults',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      allowedBotIds: $checkedConvert(
        'allowed_bot_ids',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'allowedVaults': 'allowed_vaults',
    'allowedBotIds': 'allowed_bot_ids',
  },
);

Map<String, dynamic> _$UpdatePasswordManagerRequestToJson(
  UpdatePasswordManagerRequest instance,
) => <String, dynamic>{
  'allowed_vaults': instance.allowedVaults,
  'allowed_bot_ids': ?instance.allowedBotIds,
};

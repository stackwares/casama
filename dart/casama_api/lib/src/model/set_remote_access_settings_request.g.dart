// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_remote_access_settings_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetRemoteAccessSettingsRequestCWProxy {
  SetRemoteAccessSettingsRequest privateNotifications(
    bool privateNotifications,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetRemoteAccessSettingsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetRemoteAccessSettingsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetRemoteAccessSettingsRequest call({bool privateNotifications});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetRemoteAccessSettingsRequest.copyWith(...)` or call `instanceOfSetRemoteAccessSettingsRequest.copyWith.fieldName(value)` for a single field.
class _$SetRemoteAccessSettingsRequestCWProxyImpl
    implements _$SetRemoteAccessSettingsRequestCWProxy {
  const _$SetRemoteAccessSettingsRequestCWProxyImpl(this._value);

  final SetRemoteAccessSettingsRequest _value;

  @override
  SetRemoteAccessSettingsRequest privateNotifications(
    bool privateNotifications,
  ) => call(privateNotifications: privateNotifications);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetRemoteAccessSettingsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetRemoteAccessSettingsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetRemoteAccessSettingsRequest call({
    Object? privateNotifications = const $CopyWithPlaceholder(),
  }) {
    return SetRemoteAccessSettingsRequest(
      privateNotifications:
          privateNotifications == const $CopyWithPlaceholder() ||
              privateNotifications == null
          ? _value.privateNotifications
          // ignore: cast_nullable_to_non_nullable
          : privateNotifications as bool,
    );
  }
}

extension $SetRemoteAccessSettingsRequestCopyWith
    on SetRemoteAccessSettingsRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetRemoteAccessSettingsRequest.copyWith(...)` or `instanceOfSetRemoteAccessSettingsRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetRemoteAccessSettingsRequestCWProxy get copyWith =>
      _$SetRemoteAccessSettingsRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetRemoteAccessSettingsRequest _$SetRemoteAccessSettingsRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SetRemoteAccessSettingsRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['private_notifications']);
  final val = SetRemoteAccessSettingsRequest(
    privateNotifications: $checkedConvert(
      'private_notifications',
      (v) => v as bool,
    ),
  );
  return val;
}, fieldKeyMap: const {'privateNotifications': 'private_notifications'});

Map<String, dynamic> _$SetRemoteAccessSettingsRequestToJson(
  SetRemoteAccessSettingsRequest instance,
) => <String, dynamic>{'private_notifications': instance.privateNotifications};

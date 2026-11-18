// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ask_device_permission_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AskDevicePermissionRequestCWProxy {
  AskDevicePermissionRequest permission(String permission);

  AskDevicePermissionRequest do_(AskDevicePermissionRequestDo_Enum do_);

  AskDevicePermissionRequest botId(String? botId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AskDevicePermissionRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AskDevicePermissionRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  AskDevicePermissionRequest call({
    String permission,
    AskDevicePermissionRequestDo_Enum do_,
    String? botId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAskDevicePermissionRequest.copyWith(...)` or call `instanceOfAskDevicePermissionRequest.copyWith.fieldName(value)` for a single field.
class _$AskDevicePermissionRequestCWProxyImpl
    implements _$AskDevicePermissionRequestCWProxy {
  const _$AskDevicePermissionRequestCWProxyImpl(this._value);

  final AskDevicePermissionRequest _value;

  @override
  AskDevicePermissionRequest permission(String permission) =>
      call(permission: permission);

  @override
  AskDevicePermissionRequest do_(AskDevicePermissionRequestDo_Enum do_) =>
      call(do_: do_);

  @override
  AskDevicePermissionRequest botId(String? botId) => call(botId: botId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AskDevicePermissionRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AskDevicePermissionRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AskDevicePermissionRequest call({
    Object? permission = const $CopyWithPlaceholder(),
    Object? do_ = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
  }) {
    return AskDevicePermissionRequest(
      permission:
          permission == const $CopyWithPlaceholder() || permission == null
          ? _value.permission
          // ignore: cast_nullable_to_non_nullable
          : permission as String,
      do_: do_ == const $CopyWithPlaceholder() || do_ == null
          ? _value.do_
          // ignore: cast_nullable_to_non_nullable
          : do_ as AskDevicePermissionRequestDo_Enum,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String?,
    );
  }
}

extension $AskDevicePermissionRequestCopyWith on AskDevicePermissionRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAskDevicePermissionRequest.copyWith(...)` or `instanceOfAskDevicePermissionRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AskDevicePermissionRequestCWProxy get copyWith =>
      _$AskDevicePermissionRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AskDevicePermissionRequest _$AskDevicePermissionRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AskDevicePermissionRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['permission', 'do']);
  final val = AskDevicePermissionRequest(
    permission: $checkedConvert('permission', (v) => v as String),
    do_: $checkedConvert(
      'do',
      (v) => $enumDecode(_$AskDevicePermissionRequestDo_EnumEnumMap, v),
    ),
    botId: $checkedConvert('bot_id', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'do_': 'do', 'botId': 'bot_id'});

Map<String, dynamic> _$AskDevicePermissionRequestToJson(
  AskDevicePermissionRequest instance,
) => <String, dynamic>{
  'permission': instance.permission,
  'do': _$AskDevicePermissionRequestDo_EnumEnumMap[instance.do_]!,
  'bot_id': ?instance.botId,
};

const _$AskDevicePermissionRequestDo_EnumEnumMap = {
  AskDevicePermissionRequestDo_Enum.request: 'request',
  AskDevicePermissionRequestDo_Enum.openSettings: 'open_settings',
  AskDevicePermissionRequestDo_Enum.relaunch: 'relaunch',
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_channel_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateChannelRequestCWProxy {
  UpdateChannelRequest name(String? name);

  UpdateChannelRequest allowedSenders(List<String>? allowedSenders);

  UpdateChannelRequest enabled(bool? enabled);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateChannelRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateChannelRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateChannelRequest call({
    String? name,
    List<String>? allowedSenders,
    bool? enabled,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateChannelRequest.copyWith(...)` or call `instanceOfUpdateChannelRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateChannelRequestCWProxyImpl
    implements _$UpdateChannelRequestCWProxy {
  const _$UpdateChannelRequestCWProxyImpl(this._value);

  final UpdateChannelRequest _value;

  @override
  UpdateChannelRequest name(String? name) => call(name: name);

  @override
  UpdateChannelRequest allowedSenders(List<String>? allowedSenders) =>
      call(allowedSenders: allowedSenders);

  @override
  UpdateChannelRequest enabled(bool? enabled) => call(enabled: enabled);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateChannelRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateChannelRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateChannelRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? allowedSenders = const $CopyWithPlaceholder(),
    Object? enabled = const $CopyWithPlaceholder(),
  }) {
    return UpdateChannelRequest(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      allowedSenders: allowedSenders == const $CopyWithPlaceholder()
          ? _value.allowedSenders
          // ignore: cast_nullable_to_non_nullable
          : allowedSenders as List<String>?,
      enabled: enabled == const $CopyWithPlaceholder()
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool?,
    );
  }
}

extension $UpdateChannelRequestCopyWith on UpdateChannelRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateChannelRequest.copyWith(...)` or `instanceOfUpdateChannelRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateChannelRequestCWProxy get copyWith =>
      _$UpdateChannelRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateChannelRequest _$UpdateChannelRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UpdateChannelRequest', json, ($checkedConvert) {
  final val = UpdateChannelRequest(
    name: $checkedConvert('name', (v) => v as String?),
    allowedSenders: $checkedConvert(
      'allowed_senders',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
    ),
    enabled: $checkedConvert('enabled', (v) => v as bool?),
  );
  return val;
}, fieldKeyMap: const {'allowedSenders': 'allowed_senders'});

Map<String, dynamic> _$UpdateChannelRequestToJson(
  UpdateChannelRequest instance,
) => <String, dynamic>{
  'name': ?instance.name,
  'allowed_senders': ?instance.allowedSenders,
  'enabled': ?instance.enabled,
};

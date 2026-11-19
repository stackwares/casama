// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_chat_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SupportChatRequestCWProxy {
  SupportChatRequest orgId(String? orgId);

  SupportChatRequest messages(List<SupportMessage> messages);

  SupportChatRequest features(List<String>? features);

  SupportChatRequest appVersion(String? appVersion);

  SupportChatRequest platform(String? platform);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportChatRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportChatRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SupportChatRequest call({
    String? orgId,
    List<SupportMessage> messages,
    List<String>? features,
    String? appVersion,
    String? platform,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSupportChatRequest.copyWith(...)` or call `instanceOfSupportChatRequest.copyWith.fieldName(value)` for a single field.
class _$SupportChatRequestCWProxyImpl implements _$SupportChatRequestCWProxy {
  const _$SupportChatRequestCWProxyImpl(this._value);

  final SupportChatRequest _value;

  @override
  SupportChatRequest orgId(String? orgId) => call(orgId: orgId);

  @override
  SupportChatRequest messages(List<SupportMessage> messages) =>
      call(messages: messages);

  @override
  SupportChatRequest features(List<String>? features) =>
      call(features: features);

  @override
  SupportChatRequest appVersion(String? appVersion) =>
      call(appVersion: appVersion);

  @override
  SupportChatRequest platform(String? platform) => call(platform: platform);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportChatRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportChatRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SupportChatRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? messages = const $CopyWithPlaceholder(),
    Object? features = const $CopyWithPlaceholder(),
    Object? appVersion = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
  }) {
    return SupportChatRequest(
      orgId: orgId == const $CopyWithPlaceholder()
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String?,
      messages: messages == const $CopyWithPlaceholder() || messages == null
          ? _value.messages
          // ignore: cast_nullable_to_non_nullable
          : messages as List<SupportMessage>,
      features: features == const $CopyWithPlaceholder()
          ? _value.features
          // ignore: cast_nullable_to_non_nullable
          : features as List<String>?,
      appVersion: appVersion == const $CopyWithPlaceholder()
          ? _value.appVersion
          // ignore: cast_nullable_to_non_nullable
          : appVersion as String?,
      platform: platform == const $CopyWithPlaceholder()
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as String?,
    );
  }
}

extension $SupportChatRequestCopyWith on SupportChatRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSupportChatRequest.copyWith(...)` or `instanceOfSupportChatRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SupportChatRequestCWProxy get copyWith =>
      _$SupportChatRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportChatRequest _$SupportChatRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SupportChatRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['messages']);
      final val = SupportChatRequest(
        orgId: $checkedConvert('org_id', (v) => v as String?),
        messages: $checkedConvert(
          'messages',
          (v) => (v as List<dynamic>)
              .map((e) => SupportMessage.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        features: $checkedConvert(
          'features',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        appVersion: $checkedConvert('app_version', (v) => v as String?),
        platform: $checkedConvert('platform', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'orgId': 'org_id', 'appVersion': 'app_version'});

Map<String, dynamic> _$SupportChatRequestToJson(SupportChatRequest instance) =>
    <String, dynamic>{
      'org_id': ?instance.orgId,
      'messages': instance.messages.map((e) => e.toJson()).toList(),
      'features': ?instance.features,
      'app_version': ?instance.appVersion,
      'platform': ?instance.platform,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_ticket_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SupportTicketRequestCWProxy {
  SupportTicketRequest orgId(String? orgId);

  SupportTicketRequest topic(SupportTopic topic);

  SupportTicketRequest message(String message);

  SupportTicketRequest transcript(List<SupportMessage>? transcript);

  SupportTicketRequest appVersion(String? appVersion);

  SupportTicketRequest platform(String? platform);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportTicketRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportTicketRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SupportTicketRequest call({
    String? orgId,
    SupportTopic topic,
    String message,
    List<SupportMessage>? transcript,
    String? appVersion,
    String? platform,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSupportTicketRequest.copyWith(...)` or call `instanceOfSupportTicketRequest.copyWith.fieldName(value)` for a single field.
class _$SupportTicketRequestCWProxyImpl
    implements _$SupportTicketRequestCWProxy {
  const _$SupportTicketRequestCWProxyImpl(this._value);

  final SupportTicketRequest _value;

  @override
  SupportTicketRequest orgId(String? orgId) => call(orgId: orgId);

  @override
  SupportTicketRequest topic(SupportTopic topic) => call(topic: topic);

  @override
  SupportTicketRequest message(String message) => call(message: message);

  @override
  SupportTicketRequest transcript(List<SupportMessage>? transcript) =>
      call(transcript: transcript);

  @override
  SupportTicketRequest appVersion(String? appVersion) =>
      call(appVersion: appVersion);

  @override
  SupportTicketRequest platform(String? platform) => call(platform: platform);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportTicketRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportTicketRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SupportTicketRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? topic = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
    Object? transcript = const $CopyWithPlaceholder(),
    Object? appVersion = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
  }) {
    return SupportTicketRequest(
      orgId: orgId == const $CopyWithPlaceholder()
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String?,
      topic: topic == const $CopyWithPlaceholder() || topic == null
          ? _value.topic
          // ignore: cast_nullable_to_non_nullable
          : topic as SupportTopic,
      message: message == const $CopyWithPlaceholder() || message == null
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
      transcript: transcript == const $CopyWithPlaceholder()
          ? _value.transcript
          // ignore: cast_nullable_to_non_nullable
          : transcript as List<SupportMessage>?,
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

extension $SupportTicketRequestCopyWith on SupportTicketRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSupportTicketRequest.copyWith(...)` or `instanceOfSupportTicketRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SupportTicketRequestCWProxy get copyWith =>
      _$SupportTicketRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportTicketRequest _$SupportTicketRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SupportTicketRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['topic', 'message']);
  final val = SupportTicketRequest(
    orgId: $checkedConvert('org_id', (v) => v as String?),
    topic: $checkedConvert(
      'topic',
      (v) => $enumDecode(_$SupportTopicEnumMap, v),
    ),
    message: $checkedConvert('message', (v) => v as String),
    transcript: $checkedConvert(
      'transcript',
      (v) => (v as List<dynamic>?)
          ?.map((e) => SupportMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    appVersion: $checkedConvert('app_version', (v) => v as String?),
    platform: $checkedConvert('platform', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'orgId': 'org_id', 'appVersion': 'app_version'});

Map<String, dynamic> _$SupportTicketRequestToJson(
  SupportTicketRequest instance,
) => <String, dynamic>{
  'org_id': ?instance.orgId,
  'topic': _$SupportTopicEnumMap[instance.topic]!,
  'message': instance.message,
  'transcript': ?instance.transcript?.map((e) => e.toJson()).toList(),
  'app_version': ?instance.appVersion,
  'platform': ?instance.platform,
};

const _$SupportTopicEnumMap = {
  SupportTopic.billing: 'billing',
  SupportTopic.broken: 'broken',
  SupportTopic.account: 'account',
  SupportTopic.question: 'question',
  SupportTopic.other: 'other',
};

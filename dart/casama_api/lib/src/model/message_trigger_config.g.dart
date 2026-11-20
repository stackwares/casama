// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_trigger_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MessageTriggerConfigCWProxy {
  MessageTriggerConfig channelId(String? channelId);

  MessageTriggerConfig channelKind(
    MessageTriggerConfigChannelKindEnum? channelKind,
  );

  MessageTriggerConfig sender(String? sender);

  MessageTriggerConfig subjectMatch(String? subjectMatch);

  MessageTriggerConfig textMatch(String? textMatch);

  MessageTriggerConfig toTag(String? toTag);

  MessageTriggerConfig allowUnconfirmed(bool? allowUnconfirmed);

  MessageTriggerConfig includeAutomatic(bool? includeAutomatic);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MessageTriggerConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MessageTriggerConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  MessageTriggerConfig call({
    String? channelId,
    MessageTriggerConfigChannelKindEnum? channelKind,
    String? sender,
    String? subjectMatch,
    String? textMatch,
    String? toTag,
    bool? allowUnconfirmed,
    bool? includeAutomatic,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMessageTriggerConfig.copyWith(...)` or call `instanceOfMessageTriggerConfig.copyWith.fieldName(value)` for a single field.
class _$MessageTriggerConfigCWProxyImpl
    implements _$MessageTriggerConfigCWProxy {
  const _$MessageTriggerConfigCWProxyImpl(this._value);

  final MessageTriggerConfig _value;

  @override
  MessageTriggerConfig channelId(String? channelId) =>
      call(channelId: channelId);

  @override
  MessageTriggerConfig channelKind(
    MessageTriggerConfigChannelKindEnum? channelKind,
  ) => call(channelKind: channelKind);

  @override
  MessageTriggerConfig sender(String? sender) => call(sender: sender);

  @override
  MessageTriggerConfig subjectMatch(String? subjectMatch) =>
      call(subjectMatch: subjectMatch);

  @override
  MessageTriggerConfig textMatch(String? textMatch) =>
      call(textMatch: textMatch);

  @override
  MessageTriggerConfig toTag(String? toTag) => call(toTag: toTag);

  @override
  MessageTriggerConfig allowUnconfirmed(bool? allowUnconfirmed) =>
      call(allowUnconfirmed: allowUnconfirmed);

  @override
  MessageTriggerConfig includeAutomatic(bool? includeAutomatic) =>
      call(includeAutomatic: includeAutomatic);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MessageTriggerConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MessageTriggerConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MessageTriggerConfig call({
    Object? channelId = const $CopyWithPlaceholder(),
    Object? channelKind = const $CopyWithPlaceholder(),
    Object? sender = const $CopyWithPlaceholder(),
    Object? subjectMatch = const $CopyWithPlaceholder(),
    Object? textMatch = const $CopyWithPlaceholder(),
    Object? toTag = const $CopyWithPlaceholder(),
    Object? allowUnconfirmed = const $CopyWithPlaceholder(),
    Object? includeAutomatic = const $CopyWithPlaceholder(),
  }) {
    return MessageTriggerConfig(
      channelId: channelId == const $CopyWithPlaceholder()
          ? _value.channelId
          // ignore: cast_nullable_to_non_nullable
          : channelId as String?,
      channelKind: channelKind == const $CopyWithPlaceholder()
          ? _value.channelKind
          // ignore: cast_nullable_to_non_nullable
          : channelKind as MessageTriggerConfigChannelKindEnum?,
      sender: sender == const $CopyWithPlaceholder()
          ? _value.sender
          // ignore: cast_nullable_to_non_nullable
          : sender as String?,
      subjectMatch: subjectMatch == const $CopyWithPlaceholder()
          ? _value.subjectMatch
          // ignore: cast_nullable_to_non_nullable
          : subjectMatch as String?,
      textMatch: textMatch == const $CopyWithPlaceholder()
          ? _value.textMatch
          // ignore: cast_nullable_to_non_nullable
          : textMatch as String?,
      toTag: toTag == const $CopyWithPlaceholder()
          ? _value.toTag
          // ignore: cast_nullable_to_non_nullable
          : toTag as String?,
      allowUnconfirmed: allowUnconfirmed == const $CopyWithPlaceholder()
          ? _value.allowUnconfirmed
          // ignore: cast_nullable_to_non_nullable
          : allowUnconfirmed as bool?,
      includeAutomatic: includeAutomatic == const $CopyWithPlaceholder()
          ? _value.includeAutomatic
          // ignore: cast_nullable_to_non_nullable
          : includeAutomatic as bool?,
    );
  }
}

extension $MessageTriggerConfigCopyWith on MessageTriggerConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMessageTriggerConfig.copyWith(...)` or `instanceOfMessageTriggerConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MessageTriggerConfigCWProxy get copyWith =>
      _$MessageTriggerConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageTriggerConfig _$MessageTriggerConfigFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'MessageTriggerConfig',
  json,
  ($checkedConvert) {
    final val = MessageTriggerConfig(
      channelId: $checkedConvert('channel_id', (v) => v as String?),
      channelKind: $checkedConvert(
        'channel_kind',
        (v) => $enumDecodeNullable(
          _$MessageTriggerConfigChannelKindEnumEnumMap,
          v,
        ),
      ),
      sender: $checkedConvert('sender', (v) => v as String?),
      subjectMatch: $checkedConvert('subject_match', (v) => v as String?),
      textMatch: $checkedConvert('text_match', (v) => v as String?),
      toTag: $checkedConvert('to_tag', (v) => v as String?),
      allowUnconfirmed: $checkedConvert('allow_unconfirmed', (v) => v as bool?),
      includeAutomatic: $checkedConvert('include_automatic', (v) => v as bool?),
    );
    return val;
  },
  fieldKeyMap: const {
    'channelId': 'channel_id',
    'channelKind': 'channel_kind',
    'subjectMatch': 'subject_match',
    'textMatch': 'text_match',
    'toTag': 'to_tag',
    'allowUnconfirmed': 'allow_unconfirmed',
    'includeAutomatic': 'include_automatic',
  },
);

Map<String, dynamic> _$MessageTriggerConfigToJson(
  MessageTriggerConfig instance,
) => <String, dynamic>{
  'channel_id': ?instance.channelId,
  'channel_kind':
      ?_$MessageTriggerConfigChannelKindEnumEnumMap[instance.channelKind],
  'sender': ?instance.sender,
  'subject_match': ?instance.subjectMatch,
  'text_match': ?instance.textMatch,
  'to_tag': ?instance.toTag,
  'allow_unconfirmed': ?instance.allowUnconfirmed,
  'include_automatic': ?instance.includeAutomatic,
};

const _$MessageTriggerConfigChannelKindEnumEnumMap = {
  MessageTriggerConfigChannelKindEnum.telegram: 'telegram',
  MessageTriggerConfigChannelKindEnum.email: 'email',
  MessageTriggerConfigChannelKindEnum.sms: 'sms',
  MessageTriggerConfigChannelKindEnum.slack: 'slack',
  MessageTriggerConfigChannelKindEnum.whatsapp: 'whatsapp',
  MessageTriggerConfigChannelKindEnum.messenger: 'messenger',
  MessageTriggerConfigChannelKindEnum.feishu: 'feishu',
  MessageTriggerConfigChannelKindEnum.imessage: 'imessage',
  MessageTriggerConfigChannelKindEnum.teams: 'teams',
  MessageTriggerConfigChannelKindEnum.discord: 'discord',
  MessageTriggerConfigChannelKindEnum.linear: 'linear',
  MessageTriggerConfigChannelKindEnum.jira: 'jira',
};

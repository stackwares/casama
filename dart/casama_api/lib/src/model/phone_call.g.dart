// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_call.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PhoneCallCWProxy {
  PhoneCall id(String id);

  PhoneCall botId(String botId);

  PhoneCall botName(String botName);

  PhoneCall reason(String reason);

  PhoneCall status(PhoneCallStatusEnum status);

  PhoneCall conversationId(String? conversationId);

  PhoneCall expiresAt(DateTime expiresAt);

  PhoneCall createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PhoneCall(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PhoneCall(...).copyWith(id: 12, name: "My name")
  /// ```
  PhoneCall call({
    String id,
    String botId,
    String botName,
    String reason,
    PhoneCallStatusEnum status,
    String? conversationId,
    DateTime expiresAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPhoneCall.copyWith(...)` or call `instanceOfPhoneCall.copyWith.fieldName(value)` for a single field.
class _$PhoneCallCWProxyImpl implements _$PhoneCallCWProxy {
  const _$PhoneCallCWProxyImpl(this._value);

  final PhoneCall _value;

  @override
  PhoneCall id(String id) => call(id: id);

  @override
  PhoneCall botId(String botId) => call(botId: botId);

  @override
  PhoneCall botName(String botName) => call(botName: botName);

  @override
  PhoneCall reason(String reason) => call(reason: reason);

  @override
  PhoneCall status(PhoneCallStatusEnum status) => call(status: status);

  @override
  PhoneCall conversationId(String? conversationId) =>
      call(conversationId: conversationId);

  @override
  PhoneCall expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  @override
  PhoneCall createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PhoneCall(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PhoneCall(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PhoneCall call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? botName = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return PhoneCall(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      botName: botName == const $CopyWithPlaceholder() || botName == null
          ? _value.botName
          // ignore: cast_nullable_to_non_nullable
          : botName as String,
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as PhoneCallStatusEnum,
      conversationId: conversationId == const $CopyWithPlaceholder()
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String?,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $PhoneCallCopyWith on PhoneCall {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPhoneCall.copyWith(...)` or `instanceOfPhoneCall.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PhoneCallCWProxy get copyWith => _$PhoneCallCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhoneCall _$PhoneCallFromJson(Map<String, dynamic> json) => $checkedCreate(
  'PhoneCall',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'bot_id',
        'bot_name',
        'reason',
        'status',
        'conversation_id',
        'expires_at',
        'created_at',
      ],
    );
    final val = PhoneCall(
      id: $checkedConvert('id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      botName: $checkedConvert('bot_name', (v) => v as String),
      reason: $checkedConvert('reason', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$PhoneCallStatusEnumEnumMap, v),
      ),
      conversationId: $checkedConvert('conversation_id', (v) => v as String?),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => DateTime.parse(v as String),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'botName': 'bot_name',
    'conversationId': 'conversation_id',
    'expiresAt': 'expires_at',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$PhoneCallToJson(PhoneCall instance) => <String, dynamic>{
  'id': instance.id,
  'bot_id': instance.botId,
  'bot_name': instance.botName,
  'reason': instance.reason,
  'status': _$PhoneCallStatusEnumEnumMap[instance.status]!,
  'conversation_id': instance.conversationId,
  'expires_at': instance.expiresAt.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
};

const _$PhoneCallStatusEnumEnumMap = {
  PhoneCallStatusEnum.ringing: 'ringing',
  PhoneCallStatusEnum.answered: 'answered',
  PhoneCallStatusEnum.declined: 'declined',
  PhoneCallStatusEnum.missed: 'missed',
  PhoneCallStatusEnum.cancelled: 'cancelled',
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'takeover_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TakeoverRequestCWProxy {
  TakeoverRequest id(String id);

  TakeoverRequest botId(String botId);

  TakeoverRequest runId(String runId);

  TakeoverRequest computerId(String computerId);

  TakeoverRequest reason(String reason);

  TakeoverRequest status(TakeoverRequestStatusEnum status);

  TakeoverRequest note(String? note);

  TakeoverRequest expiresAt(DateTime expiresAt);

  TakeoverRequest createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TakeoverRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TakeoverRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  TakeoverRequest call({
    String id,
    String botId,
    String runId,
    String computerId,
    String reason,
    TakeoverRequestStatusEnum status,
    String? note,
    DateTime expiresAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTakeoverRequest.copyWith(...)` or call `instanceOfTakeoverRequest.copyWith.fieldName(value)` for a single field.
class _$TakeoverRequestCWProxyImpl implements _$TakeoverRequestCWProxy {
  const _$TakeoverRequestCWProxyImpl(this._value);

  final TakeoverRequest _value;

  @override
  TakeoverRequest id(String id) => call(id: id);

  @override
  TakeoverRequest botId(String botId) => call(botId: botId);

  @override
  TakeoverRequest runId(String runId) => call(runId: runId);

  @override
  TakeoverRequest computerId(String computerId) => call(computerId: computerId);

  @override
  TakeoverRequest reason(String reason) => call(reason: reason);

  @override
  TakeoverRequest status(TakeoverRequestStatusEnum status) =>
      call(status: status);

  @override
  TakeoverRequest note(String? note) => call(note: note);

  @override
  TakeoverRequest expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  @override
  TakeoverRequest createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TakeoverRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TakeoverRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TakeoverRequest call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? computerId = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return TakeoverRequest(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      runId: runId == const $CopyWithPlaceholder() || runId == null
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String,
      computerId:
          computerId == const $CopyWithPlaceholder() || computerId == null
          ? _value.computerId
          // ignore: cast_nullable_to_non_nullable
          : computerId as String,
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as TakeoverRequestStatusEnum,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
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

extension $TakeoverRequestCopyWith on TakeoverRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTakeoverRequest.copyWith(...)` or `instanceOfTakeoverRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TakeoverRequestCWProxy get copyWith => _$TakeoverRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TakeoverRequest _$TakeoverRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'TakeoverRequest',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'bot_id',
            'run_id',
            'computer_id',
            'reason',
            'status',
            'note',
            'expires_at',
            'created_at',
          ],
        );
        final val = TakeoverRequest(
          id: $checkedConvert('id', (v) => v as String),
          botId: $checkedConvert('bot_id', (v) => v as String),
          runId: $checkedConvert('run_id', (v) => v as String),
          computerId: $checkedConvert('computer_id', (v) => v as String),
          reason: $checkedConvert('reason', (v) => v as String),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$TakeoverRequestStatusEnumEnumMap, v),
          ),
          note: $checkedConvert('note', (v) => v as String?),
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
        'runId': 'run_id',
        'computerId': 'computer_id',
        'expiresAt': 'expires_at',
        'createdAt': 'created_at',
      },
    );

Map<String, dynamic> _$TakeoverRequestToJson(TakeoverRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bot_id': instance.botId,
      'run_id': instance.runId,
      'computer_id': instance.computerId,
      'reason': instance.reason,
      'status': _$TakeoverRequestStatusEnumEnumMap[instance.status]!,
      'note': instance.note,
      'expires_at': instance.expiresAt.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$TakeoverRequestStatusEnumEnumMap = {
  TakeoverRequestStatusEnum.pending: 'pending',
  TakeoverRequestStatusEnum.taken: 'taken',
  TakeoverRequestStatusEnum.completed: 'completed',
  TakeoverRequestStatusEnum.dismissed: 'dismissed',
  TakeoverRequestStatusEnum.expired: 'expired',
};

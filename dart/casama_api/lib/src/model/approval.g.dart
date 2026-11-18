// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ApprovalCWProxy {
  Approval id(String id);

  Approval botId(String botId);

  Approval runId(String runId);

  Approval toolName(String toolName);

  Approval argsRedacted(Map<String, Object?> argsRedacted);

  Approval summary(String summary);

  Approval risk(Risk risk);

  Approval status(ApprovalStatusEnum status);

  Approval decidedAt(DateTime? decidedAt);

  Approval expiresAt(DateTime expiresAt);

  Approval createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Approval(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Approval(...).copyWith(id: 12, name: "My name")
  /// ```
  Approval call({
    String id,
    String botId,
    String runId,
    String toolName,
    Map<String, Object?> argsRedacted,
    String summary,
    Risk risk,
    ApprovalStatusEnum status,
    DateTime? decidedAt,
    DateTime expiresAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfApproval.copyWith(...)` or call `instanceOfApproval.copyWith.fieldName(value)` for a single field.
class _$ApprovalCWProxyImpl implements _$ApprovalCWProxy {
  const _$ApprovalCWProxyImpl(this._value);

  final Approval _value;

  @override
  Approval id(String id) => call(id: id);

  @override
  Approval botId(String botId) => call(botId: botId);

  @override
  Approval runId(String runId) => call(runId: runId);

  @override
  Approval toolName(String toolName) => call(toolName: toolName);

  @override
  Approval argsRedacted(Map<String, Object?> argsRedacted) =>
      call(argsRedacted: argsRedacted);

  @override
  Approval summary(String summary) => call(summary: summary);

  @override
  Approval risk(Risk risk) => call(risk: risk);

  @override
  Approval status(ApprovalStatusEnum status) => call(status: status);

  @override
  Approval decidedAt(DateTime? decidedAt) => call(decidedAt: decidedAt);

  @override
  Approval expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  @override
  Approval createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Approval(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Approval(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Approval call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? toolName = const $CopyWithPlaceholder(),
    Object? argsRedacted = const $CopyWithPlaceholder(),
    Object? summary = const $CopyWithPlaceholder(),
    Object? risk = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? decidedAt = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Approval(
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
      toolName: toolName == const $CopyWithPlaceholder() || toolName == null
          ? _value.toolName
          // ignore: cast_nullable_to_non_nullable
          : toolName as String,
      argsRedacted:
          argsRedacted == const $CopyWithPlaceholder() || argsRedacted == null
          ? _value.argsRedacted
          // ignore: cast_nullable_to_non_nullable
          : argsRedacted as Map<String, Object?>,
      summary: summary == const $CopyWithPlaceholder() || summary == null
          ? _value.summary
          // ignore: cast_nullable_to_non_nullable
          : summary as String,
      risk: risk == const $CopyWithPlaceholder() || risk == null
          ? _value.risk
          // ignore: cast_nullable_to_non_nullable
          : risk as Risk,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as ApprovalStatusEnum,
      decidedAt: decidedAt == const $CopyWithPlaceholder()
          ? _value.decidedAt
          // ignore: cast_nullable_to_non_nullable
          : decidedAt as DateTime?,
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

extension $ApprovalCopyWith on Approval {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfApproval.copyWith(...)` or `instanceOfApproval.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ApprovalCWProxy get copyWith => _$ApprovalCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Approval _$ApprovalFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Approval',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'bot_id',
        'run_id',
        'tool_name',
        'args_redacted',
        'summary',
        'risk',
        'status',
        'decided_at',
        'expires_at',
        'created_at',
      ],
    );
    final val = Approval(
      id: $checkedConvert('id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      runId: $checkedConvert('run_id', (v) => v as String),
      toolName: $checkedConvert('tool_name', (v) => v as String),
      argsRedacted: $checkedConvert(
        'args_redacted',
        (v) => v as Map<String, dynamic>,
      ),
      summary: $checkedConvert('summary', (v) => v as String),
      risk: $checkedConvert('risk', (v) => $enumDecode(_$RiskEnumMap, v)),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$ApprovalStatusEnumEnumMap, v),
      ),
      decidedAt: $checkedConvert(
        'decided_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
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
    'toolName': 'tool_name',
    'argsRedacted': 'args_redacted',
    'decidedAt': 'decided_at',
    'expiresAt': 'expires_at',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$ApprovalToJson(Approval instance) => <String, dynamic>{
  'id': instance.id,
  'bot_id': instance.botId,
  'run_id': instance.runId,
  'tool_name': instance.toolName,
  'args_redacted': instance.argsRedacted,
  'summary': instance.summary,
  'risk': _$RiskEnumMap[instance.risk]!,
  'status': _$ApprovalStatusEnumEnumMap[instance.status]!,
  'decided_at': instance.decidedAt?.toIso8601String(),
  'expires_at': instance.expiresAt.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
};

const _$RiskEnumMap = {
  Risk.low: 'low',
  Risk.medium: 'medium',
  Risk.high: 'high',
};

const _$ApprovalStatusEnumEnumMap = {
  ApprovalStatusEnum.pending: 'pending',
  ApprovalStatusEnum.approved: 'approved',
  ApprovalStatusEnum.denied: 'denied',
  ApprovalStatusEnum.expired: 'expired',
};

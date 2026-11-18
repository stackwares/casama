// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_ticket_row.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SupportTicketRowCWProxy {
  SupportTicketRow reference(String reference);

  SupportTicketRow topic(String topic);

  SupportTicketRow subject(String subject);

  SupportTicketRow status(SupportTicketRowStatusEnum status);

  SupportTicketRow userEmail(String? userEmail);

  SupportTicketRow orgId(String? orgId);

  SupportTicketRow orgName(String? orgName);

  SupportTicketRow createdAt(DateTime createdAt);

  SupportTicketRow closedAt(DateTime? closedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportTicketRow(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportTicketRow(...).copyWith(id: 12, name: "My name")
  /// ```
  SupportTicketRow call({
    String reference,
    String topic,
    String subject,
    SupportTicketRowStatusEnum status,
    String? userEmail,
    String? orgId,
    String? orgName,
    DateTime createdAt,
    DateTime? closedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSupportTicketRow.copyWith(...)` or call `instanceOfSupportTicketRow.copyWith.fieldName(value)` for a single field.
class _$SupportTicketRowCWProxyImpl implements _$SupportTicketRowCWProxy {
  const _$SupportTicketRowCWProxyImpl(this._value);

  final SupportTicketRow _value;

  @override
  SupportTicketRow reference(String reference) => call(reference: reference);

  @override
  SupportTicketRow topic(String topic) => call(topic: topic);

  @override
  SupportTicketRow subject(String subject) => call(subject: subject);

  @override
  SupportTicketRow status(SupportTicketRowStatusEnum status) =>
      call(status: status);

  @override
  SupportTicketRow userEmail(String? userEmail) => call(userEmail: userEmail);

  @override
  SupportTicketRow orgId(String? orgId) => call(orgId: orgId);

  @override
  SupportTicketRow orgName(String? orgName) => call(orgName: orgName);

  @override
  SupportTicketRow createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  SupportTicketRow closedAt(DateTime? closedAt) => call(closedAt: closedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportTicketRow(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportTicketRow(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SupportTicketRow call({
    Object? reference = const $CopyWithPlaceholder(),
    Object? topic = const $CopyWithPlaceholder(),
    Object? subject = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? userEmail = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? orgName = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? closedAt = const $CopyWithPlaceholder(),
  }) {
    return SupportTicketRow(
      reference: reference == const $CopyWithPlaceholder() || reference == null
          ? _value.reference
          // ignore: cast_nullable_to_non_nullable
          : reference as String,
      topic: topic == const $CopyWithPlaceholder() || topic == null
          ? _value.topic
          // ignore: cast_nullable_to_non_nullable
          : topic as String,
      subject: subject == const $CopyWithPlaceholder() || subject == null
          ? _value.subject
          // ignore: cast_nullable_to_non_nullable
          : subject as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as SupportTicketRowStatusEnum,
      userEmail: userEmail == const $CopyWithPlaceholder()
          ? _value.userEmail
          // ignore: cast_nullable_to_non_nullable
          : userEmail as String?,
      orgId: orgId == const $CopyWithPlaceholder()
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String?,
      orgName: orgName == const $CopyWithPlaceholder()
          ? _value.orgName
          // ignore: cast_nullable_to_non_nullable
          : orgName as String?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      closedAt: closedAt == const $CopyWithPlaceholder()
          ? _value.closedAt
          // ignore: cast_nullable_to_non_nullable
          : closedAt as DateTime?,
    );
  }
}

extension $SupportTicketRowCopyWith on SupportTicketRow {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSupportTicketRow.copyWith(...)` or `instanceOfSupportTicketRow.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SupportTicketRowCWProxy get copyWith => _$SupportTicketRowCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportTicketRow _$SupportTicketRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SupportTicketRow',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'reference',
            'topic',
            'subject',
            'status',
            'user_email',
            'org_id',
            'org_name',
            'created_at',
            'closed_at',
          ],
        );
        final val = SupportTicketRow(
          reference: $checkedConvert('reference', (v) => v as String),
          topic: $checkedConvert('topic', (v) => v as String),
          subject: $checkedConvert('subject', (v) => v as String),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$SupportTicketRowStatusEnumEnumMap, v),
          ),
          userEmail: $checkedConvert('user_email', (v) => v as String?),
          orgId: $checkedConvert('org_id', (v) => v as String?),
          orgName: $checkedConvert('org_name', (v) => v as String?),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          closedAt: $checkedConvert(
            'closed_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'userEmail': 'user_email',
        'orgId': 'org_id',
        'orgName': 'org_name',
        'createdAt': 'created_at',
        'closedAt': 'closed_at',
      },
    );

Map<String, dynamic> _$SupportTicketRowToJson(SupportTicketRow instance) =>
    <String, dynamic>{
      'reference': instance.reference,
      'topic': instance.topic,
      'subject': instance.subject,
      'status': _$SupportTicketRowStatusEnumEnumMap[instance.status]!,
      'user_email': instance.userEmail,
      'org_id': instance.orgId,
      'org_name': instance.orgName,
      'created_at': instance.createdAt.toIso8601String(),
      'closed_at': instance.closedAt?.toIso8601String(),
    };

const _$SupportTicketRowStatusEnumEnumMap = {
  SupportTicketRowStatusEnum.open: 'open',
  SupportTicketRowStatusEnum.closed: 'closed',
};

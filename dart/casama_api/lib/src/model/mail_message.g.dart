// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mail_message.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MailMessageCWProxy {
  MailMessage id(String id);

  MailMessage direction(MailMessageDirectionEnum direction);

  MailMessage fromAddr(String fromAddr);

  MailMessage fromName(String? fromName);

  MailMessage toTag(String toTag);

  MailMessage subject(String subject);

  MailMessage snippet(String snippet);

  MailMessage verdict(MailMessageVerdictEnum verdict);

  MailMessage senderCheck(MailMessageSenderCheckEnum senderCheck);

  MailMessage hasFiles(bool hasFiles);

  MailMessage fileCount(int fileCount);

  MailMessage size(int size);

  MailMessage conversationId(String? conversationId);

  MailMessage createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MailMessage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MailMessage(...).copyWith(id: 12, name: "My name")
  /// ```
  MailMessage call({
    String id,
    MailMessageDirectionEnum direction,
    String fromAddr,
    String? fromName,
    String toTag,
    String subject,
    String snippet,
    MailMessageVerdictEnum verdict,
    MailMessageSenderCheckEnum senderCheck,
    bool hasFiles,
    int fileCount,
    int size,
    String? conversationId,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMailMessage.copyWith(...)` or call `instanceOfMailMessage.copyWith.fieldName(value)` for a single field.
class _$MailMessageCWProxyImpl implements _$MailMessageCWProxy {
  const _$MailMessageCWProxyImpl(this._value);

  final MailMessage _value;

  @override
  MailMessage id(String id) => call(id: id);

  @override
  MailMessage direction(MailMessageDirectionEnum direction) =>
      call(direction: direction);

  @override
  MailMessage fromAddr(String fromAddr) => call(fromAddr: fromAddr);

  @override
  MailMessage fromName(String? fromName) => call(fromName: fromName);

  @override
  MailMessage toTag(String toTag) => call(toTag: toTag);

  @override
  MailMessage subject(String subject) => call(subject: subject);

  @override
  MailMessage snippet(String snippet) => call(snippet: snippet);

  @override
  MailMessage verdict(MailMessageVerdictEnum verdict) => call(verdict: verdict);

  @override
  MailMessage senderCheck(MailMessageSenderCheckEnum senderCheck) =>
      call(senderCheck: senderCheck);

  @override
  MailMessage hasFiles(bool hasFiles) => call(hasFiles: hasFiles);

  @override
  MailMessage fileCount(int fileCount) => call(fileCount: fileCount);

  @override
  MailMessage size(int size) => call(size: size);

  @override
  MailMessage conversationId(String? conversationId) =>
      call(conversationId: conversationId);

  @override
  MailMessage createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MailMessage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MailMessage(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MailMessage call({
    Object? id = const $CopyWithPlaceholder(),
    Object? direction = const $CopyWithPlaceholder(),
    Object? fromAddr = const $CopyWithPlaceholder(),
    Object? fromName = const $CopyWithPlaceholder(),
    Object? toTag = const $CopyWithPlaceholder(),
    Object? subject = const $CopyWithPlaceholder(),
    Object? snippet = const $CopyWithPlaceholder(),
    Object? verdict = const $CopyWithPlaceholder(),
    Object? senderCheck = const $CopyWithPlaceholder(),
    Object? hasFiles = const $CopyWithPlaceholder(),
    Object? fileCount = const $CopyWithPlaceholder(),
    Object? size = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return MailMessage(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      direction: direction == const $CopyWithPlaceholder() || direction == null
          ? _value.direction
          // ignore: cast_nullable_to_non_nullable
          : direction as MailMessageDirectionEnum,
      fromAddr: fromAddr == const $CopyWithPlaceholder() || fromAddr == null
          ? _value.fromAddr
          // ignore: cast_nullable_to_non_nullable
          : fromAddr as String,
      fromName: fromName == const $CopyWithPlaceholder()
          ? _value.fromName
          // ignore: cast_nullable_to_non_nullable
          : fromName as String?,
      toTag: toTag == const $CopyWithPlaceholder() || toTag == null
          ? _value.toTag
          // ignore: cast_nullable_to_non_nullable
          : toTag as String,
      subject: subject == const $CopyWithPlaceholder() || subject == null
          ? _value.subject
          // ignore: cast_nullable_to_non_nullable
          : subject as String,
      snippet: snippet == const $CopyWithPlaceholder() || snippet == null
          ? _value.snippet
          // ignore: cast_nullable_to_non_nullable
          : snippet as String,
      verdict: verdict == const $CopyWithPlaceholder() || verdict == null
          ? _value.verdict
          // ignore: cast_nullable_to_non_nullable
          : verdict as MailMessageVerdictEnum,
      senderCheck:
          senderCheck == const $CopyWithPlaceholder() || senderCheck == null
          ? _value.senderCheck
          // ignore: cast_nullable_to_non_nullable
          : senderCheck as MailMessageSenderCheckEnum,
      hasFiles: hasFiles == const $CopyWithPlaceholder() || hasFiles == null
          ? _value.hasFiles
          // ignore: cast_nullable_to_non_nullable
          : hasFiles as bool,
      fileCount: fileCount == const $CopyWithPlaceholder() || fileCount == null
          ? _value.fileCount
          // ignore: cast_nullable_to_non_nullable
          : fileCount as int,
      size: size == const $CopyWithPlaceholder() || size == null
          ? _value.size
          // ignore: cast_nullable_to_non_nullable
          : size as int,
      conversationId: conversationId == const $CopyWithPlaceholder()
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $MailMessageCopyWith on MailMessage {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMailMessage.copyWith(...)` or `instanceOfMailMessage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MailMessageCWProxy get copyWith => _$MailMessageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MailMessage _$MailMessageFromJson(Map<String, dynamic> json) => $checkedCreate(
  'MailMessage',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'direction',
        'from_addr',
        'from_name',
        'to_tag',
        'subject',
        'snippet',
        'verdict',
        'sender_check',
        'has_files',
        'file_count',
        'size',
        'conversation_id',
        'created_at',
      ],
    );
    final val = MailMessage(
      id: $checkedConvert('id', (v) => v as String),
      direction: $checkedConvert(
        'direction',
        (v) => $enumDecode(_$MailMessageDirectionEnumEnumMap, v),
      ),
      fromAddr: $checkedConvert('from_addr', (v) => v as String),
      fromName: $checkedConvert('from_name', (v) => v as String?),
      toTag: $checkedConvert('to_tag', (v) => v as String),
      subject: $checkedConvert('subject', (v) => v as String),
      snippet: $checkedConvert('snippet', (v) => v as String),
      verdict: $checkedConvert(
        'verdict',
        (v) => $enumDecode(_$MailMessageVerdictEnumEnumMap, v),
      ),
      senderCheck: $checkedConvert(
        'sender_check',
        (v) => $enumDecode(_$MailMessageSenderCheckEnumEnumMap, v),
      ),
      hasFiles: $checkedConvert('has_files', (v) => v as bool),
      fileCount: $checkedConvert('file_count', (v) => (v as num).toInt()),
      size: $checkedConvert('size', (v) => (v as num).toInt()),
      conversationId: $checkedConvert('conversation_id', (v) => v as String?),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'fromAddr': 'from_addr',
    'fromName': 'from_name',
    'toTag': 'to_tag',
    'senderCheck': 'sender_check',
    'hasFiles': 'has_files',
    'fileCount': 'file_count',
    'conversationId': 'conversation_id',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$MailMessageToJson(
  MailMessage instance,
) => <String, dynamic>{
  'id': instance.id,
  'direction': _$MailMessageDirectionEnumEnumMap[instance.direction]!,
  'from_addr': instance.fromAddr,
  'from_name': instance.fromName,
  'to_tag': instance.toTag,
  'subject': instance.subject,
  'snippet': instance.snippet,
  'verdict': _$MailMessageVerdictEnumEnumMap[instance.verdict]!,
  'sender_check': _$MailMessageSenderCheckEnumEnumMap[instance.senderCheck]!,
  'has_files': instance.hasFiles,
  'file_count': instance.fileCount,
  'size': instance.size,
  'conversation_id': instance.conversationId,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$MailMessageDirectionEnumEnumMap = {
  MailMessageDirectionEnum.in_: 'in',
  MailMessageDirectionEnum.out_: 'out',
};

const _$MailMessageVerdictEnumEnumMap = {
  MailMessageVerdictEnum.allowed: 'allowed',
  MailMessageVerdictEnum.stranger: 'stranger',
  MailMessageVerdictEnum.automatic: 'automatic',
};

const _$MailMessageSenderCheckEnumEnumMap = {
  MailMessageSenderCheckEnum.pass: 'pass',
  MailMessageSenderCheckEnum.fail: 'fail',
  MailMessageSenderCheckEnum.none: 'none',
};

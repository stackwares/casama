// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mail_message_detail.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MailMessageDetailCWProxy {
  MailMessageDetail id(String id);

  MailMessageDetail direction(MailMessageDetailDirectionEnum direction);

  MailMessageDetail fromAddr(String fromAddr);

  MailMessageDetail fromName(String? fromName);

  MailMessageDetail toTag(String toTag);

  MailMessageDetail subject(String subject);

  MailMessageDetail snippet(String snippet);

  MailMessageDetail verdict(MailMessageDetailVerdictEnum verdict);

  MailMessageDetail senderCheck(MailMessageDetailSenderCheckEnum senderCheck);

  MailMessageDetail hasFiles(bool hasFiles);

  MailMessageDetail fileCount(int fileCount);

  MailMessageDetail size(int size);

  MailMessageDetail conversationId(String? conversationId);

  MailMessageDetail createdAt(DateTime createdAt);

  MailMessageDetail text(String text);

  MailMessageDetail files(List<MailFile> files);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MailMessageDetail(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MailMessageDetail(...).copyWith(id: 12, name: "My name")
  /// ```
  MailMessageDetail call({
    String id,
    MailMessageDetailDirectionEnum direction,
    String fromAddr,
    String? fromName,
    String toTag,
    String subject,
    String snippet,
    MailMessageDetailVerdictEnum verdict,
    MailMessageDetailSenderCheckEnum senderCheck,
    bool hasFiles,
    int fileCount,
    int size,
    String? conversationId,
    DateTime createdAt,
    String text,
    List<MailFile> files,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMailMessageDetail.copyWith(...)` or call `instanceOfMailMessageDetail.copyWith.fieldName(value)` for a single field.
class _$MailMessageDetailCWProxyImpl implements _$MailMessageDetailCWProxy {
  const _$MailMessageDetailCWProxyImpl(this._value);

  final MailMessageDetail _value;

  @override
  MailMessageDetail id(String id) => call(id: id);

  @override
  MailMessageDetail direction(MailMessageDetailDirectionEnum direction) =>
      call(direction: direction);

  @override
  MailMessageDetail fromAddr(String fromAddr) => call(fromAddr: fromAddr);

  @override
  MailMessageDetail fromName(String? fromName) => call(fromName: fromName);

  @override
  MailMessageDetail toTag(String toTag) => call(toTag: toTag);

  @override
  MailMessageDetail subject(String subject) => call(subject: subject);

  @override
  MailMessageDetail snippet(String snippet) => call(snippet: snippet);

  @override
  MailMessageDetail verdict(MailMessageDetailVerdictEnum verdict) =>
      call(verdict: verdict);

  @override
  MailMessageDetail senderCheck(MailMessageDetailSenderCheckEnum senderCheck) =>
      call(senderCheck: senderCheck);

  @override
  MailMessageDetail hasFiles(bool hasFiles) => call(hasFiles: hasFiles);

  @override
  MailMessageDetail fileCount(int fileCount) => call(fileCount: fileCount);

  @override
  MailMessageDetail size(int size) => call(size: size);

  @override
  MailMessageDetail conversationId(String? conversationId) =>
      call(conversationId: conversationId);

  @override
  MailMessageDetail createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  MailMessageDetail text(String text) => call(text: text);

  @override
  MailMessageDetail files(List<MailFile> files) => call(files: files);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MailMessageDetail(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MailMessageDetail(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MailMessageDetail call({
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
    Object? text = const $CopyWithPlaceholder(),
    Object? files = const $CopyWithPlaceholder(),
  }) {
    return MailMessageDetail(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      direction: direction == const $CopyWithPlaceholder() || direction == null
          ? _value.direction
          // ignore: cast_nullable_to_non_nullable
          : direction as MailMessageDetailDirectionEnum,
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
          : verdict as MailMessageDetailVerdictEnum,
      senderCheck:
          senderCheck == const $CopyWithPlaceholder() || senderCheck == null
          ? _value.senderCheck
          // ignore: cast_nullable_to_non_nullable
          : senderCheck as MailMessageDetailSenderCheckEnum,
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
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
      files: files == const $CopyWithPlaceholder() || files == null
          ? _value.files
          // ignore: cast_nullable_to_non_nullable
          : files as List<MailFile>,
    );
  }
}

extension $MailMessageDetailCopyWith on MailMessageDetail {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMailMessageDetail.copyWith(...)` or `instanceOfMailMessageDetail.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MailMessageDetailCWProxy get copyWith =>
      _$MailMessageDetailCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MailMessageDetail _$MailMessageDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'MailMessageDetail',
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
            'text',
            'files',
          ],
        );
        final val = MailMessageDetail(
          id: $checkedConvert('id', (v) => v as String),
          direction: $checkedConvert(
            'direction',
            (v) => $enumDecode(_$MailMessageDetailDirectionEnumEnumMap, v),
          ),
          fromAddr: $checkedConvert('from_addr', (v) => v as String),
          fromName: $checkedConvert('from_name', (v) => v as String?),
          toTag: $checkedConvert('to_tag', (v) => v as String),
          subject: $checkedConvert('subject', (v) => v as String),
          snippet: $checkedConvert('snippet', (v) => v as String),
          verdict: $checkedConvert(
            'verdict',
            (v) => $enumDecode(_$MailMessageDetailVerdictEnumEnumMap, v),
          ),
          senderCheck: $checkedConvert(
            'sender_check',
            (v) => $enumDecode(_$MailMessageDetailSenderCheckEnumEnumMap, v),
          ),
          hasFiles: $checkedConvert('has_files', (v) => v as bool),
          fileCount: $checkedConvert('file_count', (v) => (v as num).toInt()),
          size: $checkedConvert('size', (v) => (v as num).toInt()),
          conversationId: $checkedConvert(
            'conversation_id',
            (v) => v as String?,
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          text: $checkedConvert('text', (v) => v as String),
          files: $checkedConvert(
            'files',
            (v) => (v as List<dynamic>)
                .map((e) => MailFile.fromJson(e as Map<String, dynamic>))
                .toList(),
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

Map<String, dynamic> _$MailMessageDetailToJson(MailMessageDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'direction': _$MailMessageDetailDirectionEnumEnumMap[instance.direction]!,
      'from_addr': instance.fromAddr,
      'from_name': instance.fromName,
      'to_tag': instance.toTag,
      'subject': instance.subject,
      'snippet': instance.snippet,
      'verdict': _$MailMessageDetailVerdictEnumEnumMap[instance.verdict]!,
      'sender_check':
          _$MailMessageDetailSenderCheckEnumEnumMap[instance.senderCheck]!,
      'has_files': instance.hasFiles,
      'file_count': instance.fileCount,
      'size': instance.size,
      'conversation_id': instance.conversationId,
      'created_at': instance.createdAt.toIso8601String(),
      'text': instance.text,
      'files': instance.files.map((e) => e.toJson()).toList(),
    };

const _$MailMessageDetailDirectionEnumEnumMap = {
  MailMessageDetailDirectionEnum.in_: 'in',
  MailMessageDetailDirectionEnum.out_: 'out',
};

const _$MailMessageDetailVerdictEnumEnumMap = {
  MailMessageDetailVerdictEnum.allowed: 'allowed',
  MailMessageDetailVerdictEnum.stranger: 'stranger',
  MailMessageDetailVerdictEnum.automatic: 'automatic',
};

const _$MailMessageDetailSenderCheckEnumEnumMap = {
  MailMessageDetailSenderCheckEnum.pass: 'pass',
  MailMessageDetailSenderCheckEnum.fail: 'fail',
  MailMessageDetailSenderCheckEnum.none: 'none',
};

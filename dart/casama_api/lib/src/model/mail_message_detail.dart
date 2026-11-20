//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/mail_file.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mail_message_detail.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MailMessageDetail {
  /// Returns a new [MailMessageDetail] instance.
  MailMessageDetail({

    required  this.id,

    required  this.direction,

    required  this.fromAddr,

    required  this.fromName,

    required  this.toTag,

    required  this.subject,

    required  this.snippet,

    required  this.verdict,

    required  this.senderCheck,

    required  this.hasFiles,

    required  this.fileCount,

    required  this.size,

    required  this.conversationId,

    required  this.createdAt,

    required  this.text,

    required  this.files,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'direction',
    required: true,
    includeIfNull: false,
  )


  final MailMessageDetailDirectionEnum direction;



  @JsonKey(
    
    name: r'from_addr',
    required: true,
    includeIfNull: false,
  )


  final String fromAddr;



  @JsonKey(
    
    name: r'from_name',
    required: true,
    includeIfNull: true,
  )


  final String? fromName;



  @JsonKey(
    
    name: r'to_tag',
    required: true,
    includeIfNull: false,
  )


  final String toTag;



  @JsonKey(
    
    name: r'subject',
    required: true,
    includeIfNull: false,
  )


  final String subject;



  @JsonKey(
    
    name: r'snippet',
    required: true,
    includeIfNull: false,
  )


  final String snippet;



  @JsonKey(
    
    name: r'verdict',
    required: true,
    includeIfNull: false,
  )


  final MailMessageDetailVerdictEnum verdict;



  @JsonKey(
    
    name: r'sender_check',
    required: true,
    includeIfNull: false,
  )


  final MailMessageDetailSenderCheckEnum senderCheck;



  @JsonKey(
    
    name: r'has_files',
    required: true,
    includeIfNull: false,
  )


  final bool hasFiles;



  @JsonKey(
    
    name: r'file_count',
    required: true,
    includeIfNull: false,
  )


  final int fileCount;



  @JsonKey(
    
    name: r'size',
    required: true,
    includeIfNull: false,
  )


  final int size;



  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: true,
  )


  final String? conversationId;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;



  @JsonKey(
    
    name: r'files',
    required: true,
    includeIfNull: false,
  )


  final List<MailFile> files;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MailMessageDetail &&
      other.id == id &&
      other.direction == direction &&
      other.fromAddr == fromAddr &&
      other.fromName == fromName &&
      other.toTag == toTag &&
      other.subject == subject &&
      other.snippet == snippet &&
      other.verdict == verdict &&
      other.senderCheck == senderCheck &&
      other.hasFiles == hasFiles &&
      other.fileCount == fileCount &&
      other.size == size &&
      other.conversationId == conversationId &&
      other.createdAt == createdAt &&
      other.text == text &&
      other.files == files;

    @override
    int get hashCode =>
        id.hashCode +
        direction.hashCode +
        fromAddr.hashCode +
        (fromName == null ? 0 : fromName.hashCode) +
        toTag.hashCode +
        subject.hashCode +
        snippet.hashCode +
        verdict.hashCode +
        senderCheck.hashCode +
        hasFiles.hashCode +
        fileCount.hashCode +
        size.hashCode +
        (conversationId == null ? 0 : conversationId.hashCode) +
        createdAt.hashCode +
        text.hashCode +
        files.hashCode;

  factory MailMessageDetail.fromJson(Map<String, dynamic> json) => _$MailMessageDetailFromJson(json);

  Map<String, dynamic> toJson() => _$MailMessageDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum MailMessageDetailDirectionEnum {
@JsonValue(r'in')
in_(r'in'),
@JsonValue(r'out')
out_(r'out');

const MailMessageDetailDirectionEnum(this.value);

final String value;

@override
String toString() => value;
}



enum MailMessageDetailVerdictEnum {
@JsonValue(r'allowed')
allowed(r'allowed'),
@JsonValue(r'stranger')
stranger(r'stranger'),
@JsonValue(r'automatic')
automatic(r'automatic');

const MailMessageDetailVerdictEnum(this.value);

final String value;

@override
String toString() => value;
}



enum MailMessageDetailSenderCheckEnum {
@JsonValue(r'pass')
pass(r'pass'),
@JsonValue(r'fail')
fail(r'fail'),
@JsonValue(r'none')
none(r'none');

const MailMessageDetailSenderCheckEnum(this.value);

final String value;

@override
String toString() => value;
}



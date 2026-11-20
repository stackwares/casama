//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mail_message.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MailMessage {
  /// Returns a new [MailMessage] instance.
  MailMessage({

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


  final MailMessageDirectionEnum direction;



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


  final MailMessageVerdictEnum verdict;



  @JsonKey(
    
    name: r'sender_check',
    required: true,
    includeIfNull: false,
  )


  final MailMessageSenderCheckEnum senderCheck;



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





    @override
    bool operator ==(Object other) => identical(this, other) || other is MailMessage &&
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
      other.createdAt == createdAt;

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
        createdAt.hashCode;

  factory MailMessage.fromJson(Map<String, dynamic> json) => _$MailMessageFromJson(json);

  Map<String, dynamic> toJson() => _$MailMessageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum MailMessageDirectionEnum {
@JsonValue(r'in')
in_(r'in'),
@JsonValue(r'out')
out_(r'out');

const MailMessageDirectionEnum(this.value);

final String value;

@override
String toString() => value;
}



enum MailMessageVerdictEnum {
@JsonValue(r'allowed')
allowed(r'allowed'),
@JsonValue(r'stranger')
stranger(r'stranger'),
@JsonValue(r'automatic')
automatic(r'automatic');

const MailMessageVerdictEnum(this.value);

final String value;

@override
String toString() => value;
}



enum MailMessageSenderCheckEnum {
@JsonValue(r'pass')
pass(r'pass'),
@JsonValue(r'fail')
fail(r'fail'),
@JsonValue(r'none')
none(r'none');

const MailMessageSenderCheckEnum(this.value);

final String value;

@override
String toString() => value;
}



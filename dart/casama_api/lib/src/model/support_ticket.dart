//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'support_ticket.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SupportTicket {
  /// Returns a new [SupportTicket] instance.
  SupportTicket({

    required  this.reference,

    required  this.replyTo,
  });

  @JsonKey(
    
    name: r'reference',
    required: true,
    includeIfNull: false,
  )


  final String reference;



  @JsonKey(
    
    name: r'reply_to',
    required: true,
    includeIfNull: false,
  )


  final String replyTo;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SupportTicket &&
      other.reference == reference &&
      other.replyTo == replyTo;

    @override
    int get hashCode =>
        reference.hashCode +
        replyTo.hashCode;

  factory SupportTicket.fromJson(Map<String, dynamic> json) => _$SupportTicketFromJson(json);

  Map<String, dynamic> toJson() => _$SupportTicketToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


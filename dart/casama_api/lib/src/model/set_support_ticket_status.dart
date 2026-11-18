//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_support_ticket_status.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetSupportTicketStatus {
  /// Returns a new [SetSupportTicketStatus] instance.
  SetSupportTicketStatus({

    required  this.status,
  });

  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final SetSupportTicketStatusStatusEnum status;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetSupportTicketStatus &&
      other.status == status;

    @override
    int get hashCode =>
        status.hashCode;

  factory SetSupportTicketStatus.fromJson(Map<String, dynamic> json) => _$SetSupportTicketStatusFromJson(json);

  Map<String, dynamic> toJson() => _$SetSupportTicketStatusToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SetSupportTicketStatusStatusEnum {
@JsonValue(r'open')
open(r'open'),
@JsonValue(r'closed')
closed(r'closed');

const SetSupportTicketStatusStatusEnum(this.value);

final String value;

@override
String toString() => value;
}



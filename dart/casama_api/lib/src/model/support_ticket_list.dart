//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/support_ticket_row.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'support_ticket_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SupportTicketList {
  /// Returns a new [SupportTicketList] instance.
  SupportTicketList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<SupportTicketRow> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SupportTicketList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory SupportTicketList.fromJson(Map<String, dynamic> json) => _$SupportTicketListFromJson(json);

  Map<String, dynamic> toJson() => _$SupportTicketListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


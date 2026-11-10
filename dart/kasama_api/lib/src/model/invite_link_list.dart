//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/invite_link.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invite_link_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InviteLinkList {
  /// Returns a new [InviteLinkList] instance.
  InviteLinkList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<InviteLink> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InviteLinkList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory InviteLinkList.fromJson(Map<String, dynamic> json) => _$InviteLinkListFromJson(json);

  Map<String, dynamic> toJson() => _$InviteLinkListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


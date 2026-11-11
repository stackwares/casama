//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/pending_invite.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pending_invite_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PendingInviteList {
  /// Returns a new [PendingInviteList] instance.
  PendingInviteList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<PendingInvite> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PendingInviteList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory PendingInviteList.fromJson(Map<String, dynamic> json) => _$PendingInviteListFromJson(json);

  Map<String, dynamic> toJson() => _$PendingInviteListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


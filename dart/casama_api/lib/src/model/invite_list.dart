//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/invite.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invite_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InviteList {
  /// Returns a new [InviteList] instance.
  InviteList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Invite> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InviteList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory InviteList.fromJson(Map<String, dynamic> json) => _$InviteListFromJson(json);

  Map<String, dynamic> toJson() => _$InviteListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


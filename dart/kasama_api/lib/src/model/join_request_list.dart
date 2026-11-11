//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/join_request.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'join_request_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class JoinRequestList {
  /// Returns a new [JoinRequestList] instance.
  JoinRequestList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<JoinRequest> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is JoinRequestList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory JoinRequestList.fromJson(Map<String, dynamic> json) => _$JoinRequestListFromJson(json);

  Map<String, dynamic> toJson() => _$JoinRequestListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


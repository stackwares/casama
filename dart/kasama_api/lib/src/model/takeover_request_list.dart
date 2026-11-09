//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/takeover_request.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'takeover_request_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TakeoverRequestList {
  /// Returns a new [TakeoverRequestList] instance.
  TakeoverRequestList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<TakeoverRequest> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TakeoverRequestList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory TakeoverRequestList.fromJson(Map<String, dynamic> json) => _$TakeoverRequestListFromJson(json);

  Map<String, dynamic> toJson() => _$TakeoverRequestListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/add_user_facts_request_items_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'add_user_facts_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AddUserFactsRequest {
  /// Returns a new [AddUserFactsRequest] instance.
  AddUserFactsRequest({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<AddUserFactsRequestItemsInner> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AddUserFactsRequest &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory AddUserFactsRequest.fromJson(Map<String, dynamic> json) => _$AddUserFactsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AddUserFactsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


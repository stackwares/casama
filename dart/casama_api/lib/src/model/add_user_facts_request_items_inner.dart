//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'add_user_facts_request_items_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AddUserFactsRequestItemsInner {
  /// Returns a new [AddUserFactsRequestItemsInner] instance.
  AddUserFactsRequestItemsInner({

     this.kind,

    required  this.content,
  });

  @JsonKey(
    
    name: r'kind',
    required: false,
    includeIfNull: false,
  )


  final AddUserFactsRequestItemsInnerKindEnum? kind;



  @JsonKey(
    
    name: r'content',
    required: true,
    includeIfNull: false,
  )


  final String content;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AddUserFactsRequestItemsInner &&
      other.kind == kind &&
      other.content == content;

    @override
    int get hashCode =>
        kind.hashCode +
        content.hashCode;

  factory AddUserFactsRequestItemsInner.fromJson(Map<String, dynamic> json) => _$AddUserFactsRequestItemsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$AddUserFactsRequestItemsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum AddUserFactsRequestItemsInnerKindEnum {
@JsonValue(r'fact')
fact(r'fact'),
@JsonValue(r'preference')
preference(r'preference');

const AddUserFactsRequestItemsInnerKindEnum(this.value);

final String value;

@override
String toString() => value;
}



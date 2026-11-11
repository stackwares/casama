//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_fact.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UserFact {
  /// Returns a new [UserFact] instance.
  UserFact({

    required  this.id,

    required  this.kind,

    required  this.content,

    required  this.pinned,

    required  this.updatedAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final UserFactKindEnum kind;



  @JsonKey(
    
    name: r'content',
    required: true,
    includeIfNull: false,
  )


  final String content;



  @JsonKey(
    
    name: r'pinned',
    required: true,
    includeIfNull: false,
  )


  final bool pinned;



  @JsonKey(
    
    name: r'updated_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime updatedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UserFact &&
      other.id == id &&
      other.kind == kind &&
      other.content == content &&
      other.pinned == pinned &&
      other.updatedAt == updatedAt;

    @override
    int get hashCode =>
        id.hashCode +
        kind.hashCode +
        content.hashCode +
        pinned.hashCode +
        updatedAt.hashCode;

  factory UserFact.fromJson(Map<String, dynamic> json) => _$UserFactFromJson(json);

  Map<String, dynamic> toJson() => _$UserFactToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum UserFactKindEnum {
@JsonValue(r'fact')
fact(r'fact'),
@JsonValue(r'preference')
preference(r'preference');

const UserFactKindEnum(this.value);

final String value;

@override
String toString() => value;
}



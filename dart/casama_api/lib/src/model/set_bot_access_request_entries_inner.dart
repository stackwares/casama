//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_bot_access_request_entries_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetBotAccessRequestEntriesInner {
  /// Returns a new [SetBotAccessRequestEntriesInner] instance.
  SetBotAccessRequestEntriesInner({

     this.userId,

     this.role,

    required  this.access,
  });

  @JsonKey(
    
    name: r'user_id',
    required: false,
    includeIfNull: false,
  )


  final String? userId;



  @JsonKey(
    
    name: r'role',
    required: false,
    includeIfNull: false,
  )


  final SetBotAccessRequestEntriesInnerRoleEnum? role;



  @JsonKey(
    
    name: r'access',
    required: true,
    includeIfNull: false,
  )


  final SetBotAccessRequestEntriesInnerAccessEnum access;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetBotAccessRequestEntriesInner &&
      other.userId == userId &&
      other.role == role &&
      other.access == access;

    @override
    int get hashCode =>
        userId.hashCode +
        role.hashCode +
        access.hashCode;

  factory SetBotAccessRequestEntriesInner.fromJson(Map<String, dynamic> json) => _$SetBotAccessRequestEntriesInnerFromJson(json);

  Map<String, dynamic> toJson() => _$SetBotAccessRequestEntriesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SetBotAccessRequestEntriesInnerRoleEnum {
@JsonValue(r'owner')
owner(r'owner'),
@JsonValue(r'admin')
admin(r'admin'),
@JsonValue(r'member')
member(r'member');

const SetBotAccessRequestEntriesInnerRoleEnum(this.value);

final String value;

@override
String toString() => value;
}



enum SetBotAccessRequestEntriesInnerAccessEnum {
@JsonValue(r'chat')
chat(r'chat'),
@JsonValue(r'edit')
edit(r'edit'),
@JsonValue(r'admin')
admin(r'admin');

const SetBotAccessRequestEntriesInnerAccessEnum(this.value);

final String value;

@override
String toString() => value;
}



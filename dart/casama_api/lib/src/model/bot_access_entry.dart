//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_access_entry.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotAccessEntry {
  /// Returns a new [BotAccessEntry] instance.
  BotAccessEntry({

    required  this.userId,

    required  this.email,

    required  this.role,

    required  this.access,
  });

  @JsonKey(
    
    name: r'user_id',
    required: true,
    includeIfNull: true,
  )


  final String? userId;



  @JsonKey(
    
    name: r'email',
    required: true,
    includeIfNull: true,
  )


  final String? email;



  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: true,
  )


  final BotAccessEntryRoleEnum? role;



  @JsonKey(
    
    name: r'access',
    required: true,
    includeIfNull: false,
  )


  final BotAccessEntryAccessEnum access;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotAccessEntry &&
      other.userId == userId &&
      other.email == email &&
      other.role == role &&
      other.access == access;

    @override
    int get hashCode =>
        (userId == null ? 0 : userId.hashCode) +
        (email == null ? 0 : email.hashCode) +
        (role == null ? 0 : role.hashCode) +
        access.hashCode;

  factory BotAccessEntry.fromJson(Map<String, dynamic> json) => _$BotAccessEntryFromJson(json);

  Map<String, dynamic> toJson() => _$BotAccessEntryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum BotAccessEntryRoleEnum {
@JsonValue(r'owner')
owner(r'owner'),
@JsonValue(r'admin')
admin(r'admin'),
@JsonValue(r'member')
member(r'member');

const BotAccessEntryRoleEnum(this.value);

final String value;

@override
String toString() => value;
}



enum BotAccessEntryAccessEnum {
@JsonValue(r'chat')
chat(r'chat'),
@JsonValue(r'edit')
edit(r'edit'),
@JsonValue(r'admin')
admin(r'admin');

const BotAccessEntryAccessEnum(this.value);

final String value;

@override
String toString() => value;
}



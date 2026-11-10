//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/bot_access_entry.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_access.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotAccess {
  /// Returns a new [BotAccess] instance.
  BotAccess({

    required  this.visibility,

    required  this.createdBy,

    required  this.entries,

    required  this.canAdmin,

    required  this.yourAccess,
  });

  @JsonKey(
    
    name: r'visibility',
    required: true,
    includeIfNull: false,
  )


  final BotAccessVisibilityEnum visibility;



  @JsonKey(
    
    name: r'created_by',
    required: true,
    includeIfNull: true,
  )


  final String? createdBy;



  @JsonKey(
    
    name: r'entries',
    required: true,
    includeIfNull: false,
  )


  final List<BotAccessEntry> entries;



  @JsonKey(
    
    name: r'can_admin',
    required: true,
    includeIfNull: false,
  )


  final bool canAdmin;



  @JsonKey(
    
    name: r'your_access',
    required: true,
    includeIfNull: false,
  )


  final BotAccessYourAccessEnum yourAccess;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotAccess &&
      other.visibility == visibility &&
      other.createdBy == createdBy &&
      other.entries == entries &&
      other.canAdmin == canAdmin &&
      other.yourAccess == yourAccess;

    @override
    int get hashCode =>
        visibility.hashCode +
        (createdBy == null ? 0 : createdBy.hashCode) +
        entries.hashCode +
        canAdmin.hashCode +
        yourAccess.hashCode;

  factory BotAccess.fromJson(Map<String, dynamic> json) => _$BotAccessFromJson(json);

  Map<String, dynamic> toJson() => _$BotAccessToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum BotAccessVisibilityEnum {
@JsonValue(r'private')
private(r'private'),
@JsonValue(r'team')
team(r'team');

const BotAccessVisibilityEnum(this.value);

final String value;

@override
String toString() => value;
}



enum BotAccessYourAccessEnum {
@JsonValue(r'chat')
chat(r'chat'),
@JsonValue(r'edit')
edit(r'edit'),
@JsonValue(r'admin')
admin(r'admin');

const BotAccessYourAccessEnum(this.value);

final String value;

@override
String toString() => value;
}



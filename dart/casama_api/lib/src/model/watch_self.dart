//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/watch_prefs.dart';
import 'package:casama_api/src/model/watch_self_person.dart';
import 'package:casama_api/src/model/watch_self_features.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_self.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchSelf {
  /// Returns a new [WatchSelf] instance.
  WatchSelf({

    required  this.keyId,

    required  this.orgId,

    required  this.orgName,

    required  this.person,

    required  this.prefs,

    required  this.hideReplyText,

    required  this.askBotId,

    required  this.features,
  });

  @JsonKey(
    
    name: r'key_id',
    required: true,
    includeIfNull: false,
  )


  final String keyId;



  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'org_name',
    required: true,
    includeIfNull: false,
  )


  final String orgName;



  @JsonKey(
    
    name: r'person',
    required: true,
    includeIfNull: false,
  )


  final WatchSelfPerson person;



  @JsonKey(
    
    name: r'prefs',
    required: true,
    includeIfNull: false,
  )


  final WatchPrefs prefs;



  @JsonKey(
    
    name: r'hide_reply_text',
    required: true,
    includeIfNull: false,
  )


  final bool hideReplyText;



  @JsonKey(
    
    name: r'ask_bot_id',
    required: true,
    includeIfNull: true,
  )


  final String? askBotId;



  @JsonKey(
    
    name: r'features',
    required: true,
    includeIfNull: false,
  )


  final WatchSelfFeatures features;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchSelf &&
      other.keyId == keyId &&
      other.orgId == orgId &&
      other.orgName == orgName &&
      other.person == person &&
      other.prefs == prefs &&
      other.hideReplyText == hideReplyText &&
      other.askBotId == askBotId &&
      other.features == features;

    @override
    int get hashCode =>
        keyId.hashCode +
        orgId.hashCode +
        orgName.hashCode +
        person.hashCode +
        prefs.hashCode +
        hideReplyText.hashCode +
        (askBotId == null ? 0 : askBotId.hashCode) +
        features.hashCode;

  factory WatchSelf.fromJson(Map<String, dynamic> json) => _$WatchSelfFromJson(json);

  Map<String, dynamic> toJson() => _$WatchSelfToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


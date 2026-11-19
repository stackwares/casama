//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_self_update.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchSelfUpdate {
  /// Returns a new [WatchSelfUpdate] instance.
  WatchSelfUpdate({

     this.pushToken,

     this.pushKind,

     this.sandbox,

     this.appVersion,

     this.osVersion,

     this.name,
  });

  @JsonKey(
    
    name: r'push_token',
    required: false,
    includeIfNull: false,
  )


  final String? pushToken;



  @JsonKey(
    
    name: r'push_kind',
    required: false,
    includeIfNull: false,
  )


  final WatchSelfUpdatePushKindEnum? pushKind;



  @JsonKey(
    
    name: r'sandbox',
    required: false,
    includeIfNull: false,
  )


  final bool? sandbox;



  @JsonKey(
    
    name: r'app_version',
    required: false,
    includeIfNull: false,
  )


  final String? appVersion;



  @JsonKey(
    
    name: r'os_version',
    required: false,
    includeIfNull: false,
  )


  final String? osVersion;



  @JsonKey(
    
    name: r'name',
    required: false,
    includeIfNull: false,
  )


  final String? name;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchSelfUpdate &&
      other.pushToken == pushToken &&
      other.pushKind == pushKind &&
      other.sandbox == sandbox &&
      other.appVersion == appVersion &&
      other.osVersion == osVersion &&
      other.name == name;

    @override
    int get hashCode =>
        (pushToken == null ? 0 : pushToken.hashCode) +
        pushKind.hashCode +
        sandbox.hashCode +
        appVersion.hashCode +
        osVersion.hashCode +
        name.hashCode;

  factory WatchSelfUpdate.fromJson(Map<String, dynamic> json) => _$WatchSelfUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$WatchSelfUpdateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum WatchSelfUpdatePushKindEnum {
@JsonValue(r'apns')
apns(r'apns'),
@JsonValue(r'fcm')
fcm(r'fcm');

const WatchSelfUpdatePushKindEnum(this.value);

final String value;

@override
String toString() => value;
}



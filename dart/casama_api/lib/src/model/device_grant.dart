//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/device_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_grant.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeviceGrant {
  /// Returns a new [DeviceGrant] instance.
  DeviceGrant({

    required  this.botId,

    required  this.botName,

    required  this.kind,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'bot_name',
    required: true,
    includeIfNull: false,
  )


  final String botName;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final DeviceKind kind;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeviceGrant &&
      other.botId == botId &&
      other.botName == botName &&
      other.kind == kind &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        botId.hashCode +
        botName.hashCode +
        kind.hashCode +
        createdAt.hashCode;

  factory DeviceGrant.fromJson(Map<String, dynamic> json) => _$DeviceGrantFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceGrantToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


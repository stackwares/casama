//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/watch_platform.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_code_info.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchCodeInfo {
  /// Returns a new [WatchCodeInfo] instance.
  WatchCodeInfo({

    required  this.platform,

    required  this.name,

    required  this.model,

    required  this.expiresAt,
  });

  @JsonKey(
    
    name: r'platform',
    required: true,
    includeIfNull: false,
  )


  final WatchPlatform platform;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'model',
    required: true,
    includeIfNull: true,
  )


  final String? model;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchCodeInfo &&
      other.platform == platform &&
      other.name == name &&
      other.model == model &&
      other.expiresAt == expiresAt;

    @override
    int get hashCode =>
        platform.hashCode +
        name.hashCode +
        (model == null ? 0 : model.hashCode) +
        expiresAt.hashCode;

  factory WatchCodeInfo.fromJson(Map<String, dynamic> json) => _$WatchCodeInfoFromJson(json);

  Map<String, dynamic> toJson() => _$WatchCodeInfoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


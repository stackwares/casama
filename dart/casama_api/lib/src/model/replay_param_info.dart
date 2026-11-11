//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'replay_param_info.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReplayParamInfo {
  /// Returns a new [ReplayParamInfo] instance.
  ReplayParamInfo({

    required  this.name,

     this.description,

     this.default_,

     this.secret,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'description',
    required: false,
    includeIfNull: false,
  )


  final String? description;



  @JsonKey(
    
    name: r'default',
    required: false,
    includeIfNull: false,
  )


  final String? default_;



  @JsonKey(
    
    name: r'secret',
    required: false,
    includeIfNull: false,
  )


  final bool? secret;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReplayParamInfo &&
      other.name == name &&
      other.description == description &&
      other.default_ == default_ &&
      other.secret == secret;

    @override
    int get hashCode =>
        name.hashCode +
        description.hashCode +
        default_.hashCode +
        secret.hashCode;

  factory ReplayParamInfo.fromJson(Map<String, dynamic> json) => _$ReplayParamInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ReplayParamInfoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


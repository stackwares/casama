//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/risk.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'integration_tools_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class IntegrationToolsInner {
  /// Returns a new [IntegrationToolsInner] instance.
  IntegrationToolsInner({

    required  this.name,

    required  this.description,

     this.risk,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'description',
    required: true,
    includeIfNull: false,
  )


  final String description;



  @JsonKey(
    
    name: r'risk',
    required: false,
    includeIfNull: false,
  )


  final Risk? risk;





    @override
    bool operator ==(Object other) => identical(this, other) || other is IntegrationToolsInner &&
      other.name == name &&
      other.description == description &&
      other.risk == risk;

    @override
    int get hashCode =>
        name.hashCode +
        description.hashCode +
        risk.hashCode;

  factory IntegrationToolsInner.fromJson(Map<String, dynamic> json) => _$IntegrationToolsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$IntegrationToolsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


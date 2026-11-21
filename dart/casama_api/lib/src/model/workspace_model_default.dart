//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'workspace_model_default.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WorkspaceModelDefault {
  /// Returns a new [WorkspaceModelDefault] instance.
  WorkspaceModelDefault({

    required  this.source_,

     this.credentialId,

     this.model,

     this.cheapModel,
  });

  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final WorkspaceModelDefaultSource_Enum source_;



  @JsonKey(
    
    name: r'credential_id',
    required: false,
    includeIfNull: false,
  )


  final String? credentialId;



  @JsonKey(
    
    name: r'model',
    required: false,
    includeIfNull: false,
  )


  final String? model;



  @JsonKey(
    
    name: r'cheap_model',
    required: false,
    includeIfNull: false,
  )


  final String? cheapModel;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WorkspaceModelDefault &&
      other.source_ == source_ &&
      other.credentialId == credentialId &&
      other.model == model &&
      other.cheapModel == cheapModel;

    @override
    int get hashCode =>
        source_.hashCode +
        (credentialId == null ? 0 : credentialId.hashCode) +
        (model == null ? 0 : model.hashCode) +
        (cheapModel == null ? 0 : cheapModel.hashCode);

  factory WorkspaceModelDefault.fromJson(Map<String, dynamic> json) => _$WorkspaceModelDefaultFromJson(json);

  Map<String, dynamic> toJson() => _$WorkspaceModelDefaultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum WorkspaceModelDefaultSource_Enum {
@JsonValue(r'casama')
casama(r'casama'),
@JsonValue(r'own')
own(r'own');

const WorkspaceModelDefaultSource_Enum(this.value);

final String value;

@override
String toString() => value;
}



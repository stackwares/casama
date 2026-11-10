//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/bot_template_file.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'import_bot_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ImportBotRequest {
  /// Returns a new [ImportBotRequest] instance.
  ImportBotRequest({

    required  this.orgId,

    required  this.template,

    required  this.credentialId,

    required  this.model,

     this.includeMemories = true,

     this.includeRoutines = true,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'template',
    required: true,
    includeIfNull: false,
  )


  final BotTemplateFile template;



      /// The model key the new bot uses
  @JsonKey(
    
    name: r'credential_id',
    required: true,
    includeIfNull: false,
  )


  final String credentialId;



  @JsonKey(
    
    name: r'model',
    required: true,
    includeIfNull: false,
  )


  final String model;



  @JsonKey(
    defaultValue: true,
    name: r'include_memories',
    required: false,
    includeIfNull: false,
  )


  final bool? includeMemories;



  @JsonKey(
    defaultValue: true,
    name: r'include_routines',
    required: false,
    includeIfNull: false,
  )


  final bool? includeRoutines;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ImportBotRequest &&
      other.orgId == orgId &&
      other.template == template &&
      other.credentialId == credentialId &&
      other.model == model &&
      other.includeMemories == includeMemories &&
      other.includeRoutines == includeRoutines;

    @override
    int get hashCode =>
        orgId.hashCode +
        template.hashCode +
        credentialId.hashCode +
        model.hashCode +
        includeMemories.hashCode +
        includeRoutines.hashCode;

  factory ImportBotRequest.fromJson(Map<String, dynamic> json) => _$ImportBotRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ImportBotRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


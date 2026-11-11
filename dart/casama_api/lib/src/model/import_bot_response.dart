//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/import_bot_response_connections_to_add_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'import_bot_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ImportBotResponse {
  /// Returns a new [ImportBotResponse] instance.
  ImportBotResponse({

    required  this.botId,

    required  this.skills,

    required  this.routines,

    required  this.memories,

    required  this.connectionsToAdd,
  });

  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'skills',
    required: true,
    includeIfNull: false,
  )


  final int skills;



  @JsonKey(
    
    name: r'routines',
    required: true,
    includeIfNull: false,
  )


  final int routines;



  @JsonKey(
    
    name: r'memories',
    required: true,
    includeIfNull: false,
  )


  final int memories;



  @JsonKey(
    
    name: r'connections_to_add',
    required: true,
    includeIfNull: false,
  )


  final List<ImportBotResponseConnectionsToAddInner> connectionsToAdd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ImportBotResponse &&
      other.botId == botId &&
      other.skills == skills &&
      other.routines == routines &&
      other.memories == memories &&
      other.connectionsToAdd == connectionsToAdd;

    @override
    int get hashCode =>
        botId.hashCode +
        skills.hashCode +
        routines.hashCode +
        memories.hashCode +
        connectionsToAdd.hashCode;

  factory ImportBotResponse.fromJson(Map<String, dynamic> json) => _$ImportBotResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ImportBotResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


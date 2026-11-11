//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'save_teach_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SaveTeachResponse {
  /// Returns a new [SaveTeachResponse] instance.
  SaveTeachResponse({

    required  this.skillId,

    required  this.conversationId,

    required  this.runId,
  });

  @JsonKey(
    
    name: r'skill_id',
    required: true,
    includeIfNull: false,
  )


  final String skillId;



  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: true,
  )


  final String? conversationId;



  @JsonKey(
    
    name: r'run_id',
    required: true,
    includeIfNull: true,
  )


  final String? runId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SaveTeachResponse &&
      other.skillId == skillId &&
      other.conversationId == conversationId &&
      other.runId == runId;

    @override
    int get hashCode =>
        skillId.hashCode +
        (conversationId == null ? 0 : conversationId.hashCode) +
        (runId == null ? 0 : runId.hashCode);

  factory SaveTeachResponse.fromJson(Map<String, dynamic> json) => _$SaveTeachResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SaveTeachResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


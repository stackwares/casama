//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'start_setup_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StartSetupResponse {
  /// Returns a new [StartSetupResponse] instance.
  StartSetupResponse({

    required  this.conversationId,

    required  this.runId,
  });

  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: false,
  )


  final String conversationId;



  @JsonKey(
    
    name: r'run_id',
    required: true,
    includeIfNull: false,
  )


  final String runId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is StartSetupResponse &&
      other.conversationId == conversationId &&
      other.runId == runId;

    @override
    int get hashCode =>
        conversationId.hashCode +
        runId.hashCode;

  factory StartSetupResponse.fromJson(Map<String, dynamic> json) => _$StartSetupResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StartSetupResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


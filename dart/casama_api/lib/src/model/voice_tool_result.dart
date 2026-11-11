//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice_tool_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VoiceToolResult {
  /// Returns a new [VoiceToolResult] instance.
  VoiceToolResult({

    required  this.status,

    required  this.runId,

    required  this.output,

    required  this.approvalId,
  });

  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final VoiceToolResultStatusEnum status;



  @JsonKey(
    
    name: r'run_id',
    required: true,
    includeIfNull: false,
  )


  final String runId;



      /// Give this to the realtime model as the function output
  @JsonKey(
    
    name: r'output',
    required: true,
    includeIfNull: false,
  )


  final String output;



  @JsonKey(
    
    name: r'approval_id',
    required: true,
    includeIfNull: true,
  )


  final String? approvalId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is VoiceToolResult &&
      other.status == status &&
      other.runId == runId &&
      other.output == output &&
      other.approvalId == approvalId;

    @override
    int get hashCode =>
        status.hashCode +
        runId.hashCode +
        output.hashCode +
        (approvalId == null ? 0 : approvalId.hashCode);

  factory VoiceToolResult.fromJson(Map<String, dynamic> json) => _$VoiceToolResultFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceToolResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum VoiceToolResultStatusEnum {
@JsonValue(r'completed')
completed(r'completed'),
@JsonValue(r'failed')
failed(r'failed'),
@JsonValue(r'waiting_approval')
waitingApproval(r'waiting_approval'),
@JsonValue(r'running')
running(r'running');

const VoiceToolResultStatusEnum(this.value);

final String value;

@override
String toString() => value;
}



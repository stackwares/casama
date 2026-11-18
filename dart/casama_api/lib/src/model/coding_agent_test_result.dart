//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'coding_agent_test_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CodingAgentTestResult {
  /// Returns a new [CodingAgentTestResult] instance.
  CodingAgentTestResult({

    required  this.ok,

    required  this.exitCode,

    required  this.timedOut,

    required  this.reply,

    required  this.output,

    required  this.command,
  });

  @JsonKey(
    
    name: r'ok',
    required: true,
    includeIfNull: false,
  )


  final bool ok;



  @JsonKey(
    
    name: r'exit_code',
    required: true,
    includeIfNull: false,
  )


  final int exitCode;



  @JsonKey(
    
    name: r'timed_out',
    required: true,
    includeIfNull: false,
  )


  final bool timedOut;



      /// The answer as Casama reads it with the chosen result
  @JsonKey(
    
    name: r'reply',
    required: true,
    includeIfNull: false,
  )


  final String reply;



      /// The end of what the command printed
  @JsonKey(
    
    name: r'output',
    required: true,
    includeIfNull: false,
  )


  final String output;



      /// The command that ran
  @JsonKey(
    
    name: r'command',
    required: true,
    includeIfNull: false,
  )


  final String command;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CodingAgentTestResult &&
      other.ok == ok &&
      other.exitCode == exitCode &&
      other.timedOut == timedOut &&
      other.reply == reply &&
      other.output == output &&
      other.command == command;

    @override
    int get hashCode =>
        ok.hashCode +
        exitCode.hashCode +
        timedOut.hashCode +
        reply.hashCode +
        output.hashCode +
        command.hashCode;

  factory CodingAgentTestResult.fromJson(Map<String, dynamic> json) => _$CodingAgentTestResultFromJson(json);

  Map<String, dynamic> toJson() => _$CodingAgentTestResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


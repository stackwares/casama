//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'test_own_coding_agent_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TestOwnCodingAgentRequest {
  /// Returns a new [TestOwnCodingAgentRequest] instance.
  TestOwnCodingAgentRequest({

    required  this.label,

    required  this.bin,

    required  this.command,

    required  this.result,

     this.timeoutMin,
  });

  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: false,
  )


  final String label;



  @JsonKey(
    
    name: r'bin',
    required: true,
    includeIfNull: false,
  )


  final String bin;



      /// Template with {task} (optionally {folder}, {result_file}); every command in it starts with bin
  @JsonKey(
    
    name: r'command',
    required: true,
    includeIfNull: false,
  )


  final String command;



      /// How the answer is read: json_result (a JSON `result`), marker (the agent writes it to {result_file}), json_field:<name>, stream_json or tail
  @JsonKey(
    
    name: r'result',
    required: true,
    includeIfNull: false,
  )


  final String result;



      /// Longest the test may take (default 3 minutes)
          // minimum: 1
          // maximum: 10
  @JsonKey(
    
    name: r'timeout_min',
    required: false,
    includeIfNull: false,
  )


  final int? timeoutMin;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TestOwnCodingAgentRequest &&
      other.label == label &&
      other.bin == bin &&
      other.command == command &&
      other.result == result &&
      other.timeoutMin == timeoutMin;

    @override
    int get hashCode =>
        label.hashCode +
        bin.hashCode +
        command.hashCode +
        result.hashCode +
        timeoutMin.hashCode;

  factory TestOwnCodingAgentRequest.fromJson(Map<String, dynamic> json) => _$TestOwnCodingAgentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TestOwnCodingAgentRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


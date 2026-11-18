//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/own_coding_agent.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_own_coding_agents_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetOwnCodingAgentsRequest {
  /// Returns a new [SetOwnCodingAgentsRequest] instance.
  SetOwnCodingAgentsRequest({

    required  this.agents,
  });

  @JsonKey(
    
    name: r'agents',
    required: true,
    includeIfNull: false,
  )


  final List<OwnCodingAgent> agents;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetOwnCodingAgentsRequest &&
      other.agents == agents;

    @override
    int get hashCode =>
        agents.hashCode;

  factory SetOwnCodingAgentsRequest.fromJson(Map<String, dynamic> json) => _$SetOwnCodingAgentsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetOwnCodingAgentsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'run_replay_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RunReplayRequest {
  /// Returns a new [RunReplayRequest] instance.
  RunReplayRequest({

     this.params,
  });

  @JsonKey(
    
    name: r'params',
    required: false,
    includeIfNull: false,
  )


  final Map<String, String>? params;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RunReplayRequest &&
      other.params == params;

    @override
    int get hashCode =>
        params.hashCode;

  factory RunReplayRequest.fromJson(Map<String, dynamic> json) => _$RunReplayRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RunReplayRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


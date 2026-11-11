//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_checkpoint_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateCheckpointRequest {
  /// Returns a new [CreateCheckpointRequest] instance.
  CreateCheckpointRequest({

    required  this.label,
  });

  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: false,
  )


  final String label;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateCheckpointRequest &&
      other.label == label;

    @override
    int get hashCode =>
        label.hashCode;

  factory CreateCheckpointRequest.fromJson(Map<String, dynamic> json) => _$CreateCheckpointRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCheckpointRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


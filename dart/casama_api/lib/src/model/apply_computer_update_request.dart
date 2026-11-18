//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'apply_computer_update_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApplyComputerUpdateRequest {
  /// Returns a new [ApplyComputerUpdateRequest] instance.
  ApplyComputerUpdateRequest({

     this.force,
  });

      /// Restart even while a command is running on the computer (default false)
  @JsonKey(
    
    name: r'force',
    required: false,
    includeIfNull: false,
  )


  final bool? force;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ApplyComputerUpdateRequest &&
      other.force == force;

    @override
    int get hashCode =>
        force.hashCode;

  factory ApplyComputerUpdateRequest.fromJson(Map<String, dynamic> json) => _$ApplyComputerUpdateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ApplyComputerUpdateRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


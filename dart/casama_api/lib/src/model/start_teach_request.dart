//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'start_teach_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StartTeachRequest {
  /// Returns a new [StartTeachRequest] instance.
  StartTeachRequest({

    required  this.computerId,

    required  this.botId,
  });

  @JsonKey(
    
    name: r'computer_id',
    required: true,
    includeIfNull: false,
  )


  final String computerId;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is StartTeachRequest &&
      other.computerId == computerId &&
      other.botId == botId;

    @override
    int get hashCode =>
        computerId.hashCode +
        botId.hashCode;

  factory StartTeachRequest.fromJson(Map<String, dynamic> json) => _$StartTeachRequestFromJson(json);

  Map<String, dynamic> toJson() => _$StartTeachRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


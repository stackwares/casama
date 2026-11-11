//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'start_welcome_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StartWelcomeRequest {
  /// Returns a new [StartWelcomeRequest] instance.
  StartWelcomeRequest({

     this.firstName,

     this.botName,
  });

  @JsonKey(
    
    name: r'first_name',
    required: false,
    includeIfNull: false,
  )


  final String? firstName;



  @JsonKey(
    
    name: r'bot_name',
    required: false,
    includeIfNull: false,
  )


  final String? botName;





    @override
    bool operator ==(Object other) => identical(this, other) || other is StartWelcomeRequest &&
      other.firstName == firstName &&
      other.botName == botName;

    @override
    int get hashCode =>
        firstName.hashCode +
        botName.hashCode;

  factory StartWelcomeRequest.fromJson(Map<String, dynamic> json) => _$StartWelcomeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$StartWelcomeRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


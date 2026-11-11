//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'run_failed_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RunFailedEventPayload {
  /// Returns a new [RunFailedEventPayload] instance.
  RunFailedEventPayload({

    required  this.errorCode,

    required  this.message,
  });

  @JsonKey(
    
    name: r'error_code',
    required: true,
    includeIfNull: false,
  )


  final String errorCode;



  @JsonKey(
    
    name: r'message',
    required: true,
    includeIfNull: false,
  )


  final String message;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RunFailedEventPayload &&
      other.errorCode == errorCode &&
      other.message == message;

    @override
    int get hashCode =>
        errorCode.hashCode +
        message.hashCode;

  factory RunFailedEventPayload.fromJson(Map<String, dynamic> json) => _$RunFailedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$RunFailedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model_fallback_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ModelFallbackEventPayload {
  /// Returns a new [ModelFallbackEventPayload] instance.
  ModelFallbackEventPayload({

    required  this.fromModel,

    required  this.reason,

    required  this.message,
  });

  @JsonKey(
    
    name: r'from_model',
    required: true,
    includeIfNull: false,
  )


  final String fromModel;



  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: false,
  )


  final String reason;



  @JsonKey(
    
    name: r'message',
    required: true,
    includeIfNull: false,
  )


  final String message;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ModelFallbackEventPayload &&
      other.fromModel == fromModel &&
      other.reason == reason &&
      other.message == message;

    @override
    int get hashCode =>
        fromModel.hashCode +
        reason.hashCode +
        message.hashCode;

  factory ModelFallbackEventPayload.fromJson(Map<String, dynamic> json) => _$ModelFallbackEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$ModelFallbackEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


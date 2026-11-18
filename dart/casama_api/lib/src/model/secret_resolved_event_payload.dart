//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'secret_resolved_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SecretResolvedEventPayload {
  /// Returns a new [SecretResolvedEventPayload] instance.
  SecretResolvedEventPayload({

    required  this.requestId,

    required  this.outcome,
  });

  @JsonKey(
    
    name: r'request_id',
    required: true,
    includeIfNull: false,
  )


  final String requestId;



  @JsonKey(
    
    name: r'outcome',
    required: true,
    includeIfNull: false,
  )


  final SecretResolvedEventPayloadOutcomeEnum outcome;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SecretResolvedEventPayload &&
      other.requestId == requestId &&
      other.outcome == outcome;

    @override
    int get hashCode =>
        requestId.hashCode +
        outcome.hashCode;

  factory SecretResolvedEventPayload.fromJson(Map<String, dynamic> json) => _$SecretResolvedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$SecretResolvedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SecretResolvedEventPayloadOutcomeEnum {
@JsonValue(r'fulfilled')
fulfilled(r'fulfilled'),
@JsonValue(r'declined')
declined(r'declined'),
@JsonValue(r'expired')
expired(r'expired');

const SecretResolvedEventPayloadOutcomeEnum(this.value);

final String value;

@override
String toString() => value;
}



//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ui_shown_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UiShownEventPayload {
  /// Returns a new [UiShownEventPayload] instance.
  UiShownEventPayload({

    required  this.surfaceId,

    required  this.messages,
  });

  @JsonKey(
    
    name: r'surface_id',
    required: true,
    includeIfNull: false,
  )


  final String surfaceId;



  @JsonKey(
    
    name: r'messages',
    required: true,
    includeIfNull: false,
  )


  final List<Map<String, Object?>> messages;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UiShownEventPayload &&
      other.surfaceId == surfaceId &&
      other.messages == messages;

    @override
    int get hashCode =>
        surfaceId.hashCode +
        messages.hashCode;

  factory UiShownEventPayload.fromJson(Map<String, dynamic> json) => _$UiShownEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$UiShownEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


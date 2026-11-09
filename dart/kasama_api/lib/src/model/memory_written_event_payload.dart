//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'memory_written_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MemoryWrittenEventPayload {
  /// Returns a new [MemoryWrittenEventPayload] instance.
  MemoryWrittenEventPayload({

    required  this.memoryId,

    required  this.kind,
  });

  @JsonKey(
    
    name: r'memory_id',
    required: true,
    includeIfNull: false,
  )


  final String memoryId;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final MemoryWrittenEventPayloadKindEnum kind;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MemoryWrittenEventPayload &&
      other.memoryId == memoryId &&
      other.kind == kind;

    @override
    int get hashCode =>
        memoryId.hashCode +
        kind.hashCode;

  factory MemoryWrittenEventPayload.fromJson(Map<String, dynamic> json) => _$MemoryWrittenEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$MemoryWrittenEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum MemoryWrittenEventPayloadKindEnum {
@JsonValue(r'fact')
fact(r'fact'),
@JsonValue(r'episode')
episode(r'episode'),
@JsonValue(r'summary')
summary(r'summary'),
@JsonValue(r'preference')
preference(r'preference');

const MemoryWrittenEventPayloadKindEnum(this.value);

final String value;

@override
String toString() => value;
}



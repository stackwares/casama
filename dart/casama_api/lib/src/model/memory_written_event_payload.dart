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

     this.scope,
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



  @JsonKey(
    
    name: r'scope',
    required: false,
    includeIfNull: false,
  )


  final MemoryWrittenEventPayloadScopeEnum? scope;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MemoryWrittenEventPayload &&
      other.memoryId == memoryId &&
      other.kind == kind &&
      other.scope == scope;

    @override
    int get hashCode =>
        memoryId.hashCode +
        kind.hashCode +
        scope.hashCode;

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



enum MemoryWrittenEventPayloadScopeEnum {
@JsonValue(r'bot')
bot(r'bot'),
@JsonValue(r'profile')
profile(r'profile');

const MemoryWrittenEventPayloadScopeEnum(this.value);

final String value;

@override
String toString() => value;
}



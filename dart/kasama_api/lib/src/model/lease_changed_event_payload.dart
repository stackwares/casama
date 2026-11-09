//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lease_changed_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LeaseChangedEventPayload {
  /// Returns a new [LeaseChangedEventPayload] instance.
  LeaseChangedEventPayload({

    required  this.computerId,

    required  this.holderType,

    required  this.mode,
  });

  @JsonKey(
    
    name: r'computer_id',
    required: true,
    includeIfNull: false,
  )


  final String computerId;



  @JsonKey(
    
    name: r'holder_type',
    required: true,
    includeIfNull: false,
  )


  final LeaseChangedEventPayloadHolderTypeEnum holderType;



  @JsonKey(
    
    name: r'mode',
    required: true,
    includeIfNull: false,
  )


  final LeaseChangedEventPayloadModeEnum mode;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LeaseChangedEventPayload &&
      other.computerId == computerId &&
      other.holderType == holderType &&
      other.mode == mode;

    @override
    int get hashCode =>
        computerId.hashCode +
        holderType.hashCode +
        mode.hashCode;

  factory LeaseChangedEventPayload.fromJson(Map<String, dynamic> json) => _$LeaseChangedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$LeaseChangedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum LeaseChangedEventPayloadHolderTypeEnum {
@JsonValue(r'bot')
bot(r'bot'),
@JsonValue(r'user')
user(r'user');

const LeaseChangedEventPayloadHolderTypeEnum(this.value);

final String value;

@override
String toString() => value;
}



enum LeaseChangedEventPayloadModeEnum {
@JsonValue(r'view')
view(r'view'),
@JsonValue(r'control')
control(r'control');

const LeaseChangedEventPayloadModeEnum(this.value);

final String value;

@override
String toString() => value;
}



//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/set_bot_access_request_entries_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_bot_access_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetBotAccessRequest {
  /// Returns a new [SetBotAccessRequest] instance.
  SetBotAccessRequest({

    required  this.visibility,

    required  this.entries,
  });

  @JsonKey(
    
    name: r'visibility',
    required: true,
    includeIfNull: false,
  )


  final SetBotAccessRequestVisibilityEnum visibility;



  @JsonKey(
    
    name: r'entries',
    required: true,
    includeIfNull: false,
  )


  final List<SetBotAccessRequestEntriesInner> entries;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetBotAccessRequest &&
      other.visibility == visibility &&
      other.entries == entries;

    @override
    int get hashCode =>
        visibility.hashCode +
        entries.hashCode;

  factory SetBotAccessRequest.fromJson(Map<String, dynamic> json) => _$SetBotAccessRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetBotAccessRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SetBotAccessRequestVisibilityEnum {
@JsonValue(r'private')
private(r'private'),
@JsonValue(r'team')
team(r'team');

const SetBotAccessRequestVisibilityEnum(this.value);

final String value;

@override
String toString() => value;
}



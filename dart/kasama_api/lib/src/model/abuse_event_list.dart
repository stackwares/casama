//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/abuse_event.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'abuse_event_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AbuseEventList {
  /// Returns a new [AbuseEventList] instance.
  AbuseEventList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<AbuseEvent> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AbuseEventList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory AbuseEventList.fromJson(Map<String, dynamic> json) => _$AbuseEventListFromJson(json);

  Map<String, dynamic> toJson() => _$AbuseEventListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


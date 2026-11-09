//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/run_event_envelope.dart';
import 'package:kasama_api/src/model/run_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'run_events_page.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RunEventsPage {
  /// Returns a new [RunEventsPage] instance.
  RunEventsPage({

    required  this.items,

    required  this.runStatus,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<RunEventEnvelope> items;



  @JsonKey(
    
    name: r'run_status',
    required: true,
    includeIfNull: false,
  )


  final RunStatus runStatus;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RunEventsPage &&
      other.items == items &&
      other.runStatus == runStatus;

    @override
    int get hashCode =>
        items.hashCode +
        runStatus.hashCode;

  factory RunEventsPage.fromJson(Map<String, dynamic> json) => _$RunEventsPageFromJson(json);

  Map<String, dynamic> toJson() => _$RunEventsPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


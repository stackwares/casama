//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'save_call_limits_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SaveCallLimitsRequest {
  /// Returns a new [SaveCallLimitsRequest] instance.
  SaveCallLimitsRequest({

    required  this.limits,
  });

      /// silence_seconds, heartbeat_seconds, abandoned_seconds, max_call_minutes, warning_seconds, ring_daily_cap, ring_cooldown_minutes. Replaces the saved values; a name left out or null uses the default
  @JsonKey(
    
    name: r'limits',
    required: true,
    includeIfNull: false,
  )


  final Map<String, int> limits;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SaveCallLimitsRequest &&
      other.limits == limits;

    @override
    int get hashCode =>
        limits.hashCode;

  factory SaveCallLimitsRequest.fromJson(Map<String, dynamic> json) => _$SaveCallLimitsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SaveCallLimitsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_watcher_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateWatcherRequest {
  /// Returns a new [UpdateWatcherRequest] instance.
  UpdateWatcherRequest({

    required  this.status,
  });

  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final UpdateWatcherRequestStatusEnum status;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateWatcherRequest &&
      other.status == status;

    @override
    int get hashCode =>
        status.hashCode;

  factory UpdateWatcherRequest.fromJson(Map<String, dynamic> json) => _$UpdateWatcherRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateWatcherRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum UpdateWatcherRequestStatusEnum {
@JsonValue(r'active')
active(r'active'),
@JsonValue(r'paused')
paused(r'paused');

const UpdateWatcherRequestStatusEnum(this.value);

final String value;

@override
String toString() => value;
}



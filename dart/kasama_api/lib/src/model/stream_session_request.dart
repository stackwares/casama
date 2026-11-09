//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/stream_mode.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'stream_session_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StreamSessionRequest {
  /// Returns a new [StreamSessionRequest] instance.
  StreamSessionRequest({

     this.mode,
  });

  @JsonKey(
    
    name: r'mode',
    required: false,
    includeIfNull: false,
  )


  final StreamMode? mode;





    @override
    bool operator ==(Object other) => identical(this, other) || other is StreamSessionRequest &&
      other.mode == mode;

    @override
    int get hashCode =>
        mode.hashCode;

  factory StreamSessionRequest.fromJson(Map<String, dynamic> json) => _$StreamSessionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$StreamSessionRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


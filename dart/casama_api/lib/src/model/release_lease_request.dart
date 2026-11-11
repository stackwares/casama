//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'release_lease_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReleaseLeaseRequest {
  /// Returns a new [ReleaseLeaseRequest] instance.
  ReleaseLeaseRequest({

     this.note,
  });

      /// Told to the bot on hand-back
  @JsonKey(
    
    name: r'note',
    required: false,
    includeIfNull: false,
  )


  final String? note;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReleaseLeaseRequest &&
      other.note == note;

    @override
    int get hashCode =>
        note.hashCode;

  factory ReleaseLeaseRequest.fromJson(Map<String, dynamic> json) => _$ReleaseLeaseRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ReleaseLeaseRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


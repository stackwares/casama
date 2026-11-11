//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'revert_page_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RevertPageRequest {
  /// Returns a new [RevertPageRequest] instance.
  RevertPageRequest({

    required  this.version,
  });

          // minimum: 1
  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final int version;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RevertPageRequest &&
      other.version == version;

    @override
    int get hashCode =>
        version.hashCode;

  factory RevertPageRequest.fromJson(Map<String, dynamic> json) => _$RevertPageRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RevertPageRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


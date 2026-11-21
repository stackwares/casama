//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'probe_server_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProbeServerRequest {
  /// Returns a new [ProbeServerRequest] instance.
  ProbeServerRequest({

    required  this.orgId,

    required  this.url,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ProbeServerRequest &&
      other.orgId == orgId &&
      other.url == url;

    @override
    int get hashCode =>
        orgId.hashCode +
        url.hashCode;

  factory ProbeServerRequest.fromJson(Map<String, dynamic> json) => _$ProbeServerRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ProbeServerRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


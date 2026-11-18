//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'preview_plugin_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PreviewPluginRequest {
  /// Returns a new [PreviewPluginRequest] instance.
  PreviewPluginRequest({

    required  this.orgId,

    required  this.url,

     this.commit,
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



  @JsonKey(
    
    name: r'commit',
    required: false,
    includeIfNull: false,
  )


  final String? commit;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PreviewPluginRequest &&
      other.orgId == orgId &&
      other.url == url &&
      other.commit == commit;

    @override
    int get hashCode =>
        orgId.hashCode +
        url.hashCode +
        commit.hashCode;

  factory PreviewPluginRequest.fromJson(Map<String, dynamic> json) => _$PreviewPluginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PreviewPluginRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_plugin_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdatePluginRequest {
  /// Returns a new [UpdatePluginRequest] instance.
  UpdatePluginRequest({

    required  this.commit,

     this.secrets,
  });

  @JsonKey(
    
    name: r'commit',
    required: true,
    includeIfNull: false,
  )


  final String commit;



  @JsonKey(
    
    name: r'secrets',
    required: false,
    includeIfNull: false,
  )


  final Map<String, String>? secrets;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdatePluginRequest &&
      other.commit == commit &&
      other.secrets == secrets;

    @override
    int get hashCode =>
        commit.hashCode +
        secrets.hashCode;

  factory UpdatePluginRequest.fromJson(Map<String, dynamic> json) => _$UpdatePluginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdatePluginRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_channel_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateChannelRequest {
  /// Returns a new [UpdateChannelRequest] instance.
  UpdateChannelRequest({

     this.name,

     this.allowedSenders,

     this.enabled,
  });

  @JsonKey(
    
    name: r'name',
    required: false,
    includeIfNull: false,
  )


  final String? name;



  @JsonKey(
    
    name: r'allowed_senders',
    required: false,
    includeIfNull: false,
  )


  final List<String>? allowedSenders;



  @JsonKey(
    
    name: r'enabled',
    required: false,
    includeIfNull: false,
  )


  final bool? enabled;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateChannelRequest &&
      other.name == name &&
      other.allowedSenders == allowedSenders &&
      other.enabled == enabled;

    @override
    int get hashCode =>
        name.hashCode +
        allowedSenders.hashCode +
        enabled.hashCode;

  factory UpdateChannelRequest.fromJson(Map<String, dynamic> json) => _$UpdateChannelRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateChannelRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


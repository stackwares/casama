//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'provider_connect_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProviderConnectRequest {
  /// Returns a new [ProviderConnectRequest] instance.
  ProviderConnectRequest({

    required  this.app,

     this.returnToApp,
  });

  @JsonKey(
    
    name: r'app',
    required: true,
    includeIfNull: false,
  )


  final String app;



  @JsonKey(
    
    name: r'return_to_app',
    required: false,
    includeIfNull: false,
  )


  final bool? returnToApp;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ProviderConnectRequest &&
      other.app == app &&
      other.returnToApp == returnToApp;

    @override
    int get hashCode =>
        app.hashCode +
        returnToApp.hashCode;

  factory ProviderConnectRequest.fromJson(Map<String, dynamic> json) => _$ProviderConnectRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ProviderConnectRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


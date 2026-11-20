//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'claim_mail_address_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ClaimMailAddressRequest {
  /// Returns a new [ClaimMailAddressRequest] instance.
  ClaimMailAddressRequest({

    required  this.name,

     this.surface,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'surface',
    required: false,
    includeIfNull: false,
  )


  final ClaimMailAddressRequestSurfaceEnum? surface;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ClaimMailAddressRequest &&
      other.name == name &&
      other.surface == surface;

    @override
    int get hashCode =>
        name.hashCode +
        surface.hashCode;

  factory ClaimMailAddressRequest.fromJson(Map<String, dynamic> json) => _$ClaimMailAddressRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ClaimMailAddressRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ClaimMailAddressRequestSurfaceEnum {
@JsonValue(r'profile')
profile(r'profile'),
@JsonValue(r'tool')
tool(r'tool'),
@JsonValue(r'suggestion')
suggestion(r'suggestion');

const ClaimMailAddressRequestSurfaceEnum(this.value);

final String value;

@override
String toString() => value;
}



//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'connect_domain_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConnectDomainRequest {
  /// Returns a new [ConnectDomainRequest] instance.
  ConnectDomainRequest({

    required  this.name,

     this.pageId,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'page_id',
    required: false,
    includeIfNull: false,
  )


  final String? pageId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ConnectDomainRequest &&
      other.name == name &&
      other.pageId == pageId;

    @override
    int get hashCode =>
        name.hashCode +
        pageId.hashCode;

  factory ConnectDomainRequest.fromJson(Map<String, dynamic> json) => _$ConnectDomainRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectDomainRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_join_domain_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetJoinDomainRequest {
  /// Returns a new [SetJoinDomainRequest] instance.
  SetJoinDomainRequest({

    required  this.enabled,

     this.domain,
  });

  @JsonKey(
    
    name: r'enabled',
    required: true,
    includeIfNull: false,
  )


  final bool enabled;



  @JsonKey(
    
    name: r'domain',
    required: false,
    includeIfNull: false,
  )


  final String? domain;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetJoinDomainRequest &&
      other.enabled == enabled &&
      other.domain == domain;

    @override
    int get hashCode =>
        enabled.hashCode +
        domain.hashCode;

  factory SetJoinDomainRequest.fromJson(Map<String, dynamic> json) => _$SetJoinDomainRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetJoinDomainRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


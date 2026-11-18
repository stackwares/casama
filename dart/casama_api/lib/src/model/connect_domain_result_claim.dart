//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'connect_domain_result_claim.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConnectDomainResultClaim {
  /// Returns a new [ConnectDomainResultClaim] instance.
  ConnectDomainResultClaim({

    required  this.type,

    required  this.name,

    required  this.value,
  });

  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final String type;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'value',
    required: true,
    includeIfNull: false,
  )


  final String value;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ConnectDomainResultClaim &&
      other.type == type &&
      other.name == name &&
      other.value == value;

    @override
    int get hashCode =>
        type.hashCode +
        name.hashCode +
        value.hashCode;

  factory ConnectDomainResultClaim.fromJson(Map<String, dynamic> json) => _$ConnectDomainResultClaimFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectDomainResultClaimToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


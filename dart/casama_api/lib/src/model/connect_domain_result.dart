//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/domain.dart';
import 'package:casama_api/src/model/connect_domain_result_claim.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'connect_domain_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConnectDomainResult {
  /// Returns a new [ConnectDomainResult] instance.
  ConnectDomainResult({

    required  this.domain,

    required  this.claim,
  });

  @JsonKey(
    
    name: r'domain',
    required: true,
    includeIfNull: true,
  )


  final Domain? domain;



  @JsonKey(
    
    name: r'claim',
    required: true,
    includeIfNull: true,
  )


  final ConnectDomainResultClaim? claim;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ConnectDomainResult &&
      other.domain == domain &&
      other.claim == claim;

    @override
    int get hashCode =>
        (domain == null ? 0 : domain.hashCode) +
        (claim == null ? 0 : claim.hashCode);

  factory ConnectDomainResult.fromJson(Map<String, dynamic> json) => _$ConnectDomainResultFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectDomainResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


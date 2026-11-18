//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'domain_checkout_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DomainCheckoutRequest {
  /// Returns a new [DomainCheckoutRequest] instance.
  DomainCheckoutRequest({

    required  this.name,

     this.pageId,

    required  this.acceptTerms,

     this.autoRenew,
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



  @JsonKey(
    
    name: r'accept_terms',
    required: true,
    includeIfNull: false,
  )


  final bool acceptTerms;



  @JsonKey(
    
    name: r'auto_renew',
    required: false,
    includeIfNull: false,
  )


  final bool? autoRenew;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DomainCheckoutRequest &&
      other.name == name &&
      other.pageId == pageId &&
      other.acceptTerms == acceptTerms &&
      other.autoRenew == autoRenew;

    @override
    int get hashCode =>
        name.hashCode +
        pageId.hashCode +
        acceptTerms.hashCode +
        autoRenew.hashCode;

  factory DomainCheckoutRequest.fromJson(Map<String, dynamic> json) => _$DomainCheckoutRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DomainCheckoutRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


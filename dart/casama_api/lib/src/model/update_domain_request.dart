//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_domain_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateDomainRequest {
  /// Returns a new [UpdateDomainRequest] instance.
  UpdateDomainRequest({

     this.pageId,

     this.primaryHost,

     this.autoRenew,

     this.locked,
  });

  @JsonKey(
    
    name: r'page_id',
    required: false,
    includeIfNull: false,
  )


  final String? pageId;



  @JsonKey(
    
    name: r'primary_host',
    required: false,
    includeIfNull: false,
  )


  final String? primaryHost;



  @JsonKey(
    
    name: r'auto_renew',
    required: false,
    includeIfNull: false,
  )


  final bool? autoRenew;



  @JsonKey(
    
    name: r'locked',
    required: false,
    includeIfNull: false,
  )


  final bool? locked;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateDomainRequest &&
      other.pageId == pageId &&
      other.primaryHost == primaryHost &&
      other.autoRenew == autoRenew &&
      other.locked == locked;

    @override
    int get hashCode =>
        (pageId == null ? 0 : pageId.hashCode) +
        primaryHost.hashCode +
        autoRenew.hashCode +
        locked.hashCode;

  factory UpdateDomainRequest.fromJson(Map<String, dynamic> json) => _$UpdateDomainRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateDomainRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


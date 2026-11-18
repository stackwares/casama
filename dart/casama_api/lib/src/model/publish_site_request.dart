//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'publish_site_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublishSiteRequest {
  /// Returns a new [PublishSiteRequest] instance.
  PublishSiteRequest({

     this.label,

     this.indexable,

     this.badge,
  });

  @JsonKey(
    
    name: r'label',
    required: false,
    includeIfNull: false,
  )


  final String? label;



  @JsonKey(
    
    name: r'indexable',
    required: false,
    includeIfNull: false,
  )


  final bool? indexable;



  @JsonKey(
    
    name: r'badge',
    required: false,
    includeIfNull: false,
  )


  final bool? badge;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PublishSiteRequest &&
      other.label == label &&
      other.indexable == indexable &&
      other.badge == badge;

    @override
    int get hashCode =>
        label.hashCode +
        indexable.hashCode +
        badge.hashCode;

  factory PublishSiteRequest.fromJson(Map<String, dynamic> json) => _$PublishSiteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PublishSiteRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


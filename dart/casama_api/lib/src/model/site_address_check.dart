//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'site_address_check.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SiteAddressCheck {
  /// Returns a new [SiteAddressCheck] instance.
  SiteAddressCheck({

    required  this.label,

    required  this.available,

    required  this.reason,

    required  this.message,

    required  this.url,
  });

  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: false,
  )


  final String label;



  @JsonKey(
    
    name: r'available',
    required: true,
    includeIfNull: false,
  )


  final bool available;



  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: true,
  )


  final String? reason;



  @JsonKey(
    
    name: r'message',
    required: true,
    includeIfNull: true,
  )


  final String? message;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: true,
  )


  final String? url;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SiteAddressCheck &&
      other.label == label &&
      other.available == available &&
      other.reason == reason &&
      other.message == message &&
      other.url == url;

    @override
    int get hashCode =>
        label.hashCode +
        available.hashCode +
        (reason == null ? 0 : reason.hashCode) +
        (message == null ? 0 : message.hashCode) +
        (url == null ? 0 : url.hashCode);

  factory SiteAddressCheck.fromJson(Map<String, dynamic> json) => _$SiteAddressCheckFromJson(json);

  Map<String, dynamic> toJson() => _$SiteAddressCheckToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


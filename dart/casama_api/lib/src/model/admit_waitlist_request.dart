//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admit_waitlist_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdmitWaitlistRequest {
  /// Returns a new [AdmitWaitlistRequest] instance.
  AdmitWaitlistRequest({

     this.ids,

     this.count,

     this.source_,

     this.ref,

     this.selfHosting,
  });

  @JsonKey(
    
    name: r'ids',
    required: false,
    includeIfNull: false,
  )


  final List<String>? ids;



          // minimum: 1
          // maximum: 5000
  @JsonKey(
    
    name: r'count',
    required: false,
    includeIfNull: false,
  )


  final int? count;



  @JsonKey(
    
    name: r'source',
    required: false,
    includeIfNull: false,
  )


  final String? source_;



  @JsonKey(
    
    name: r'ref',
    required: false,
    includeIfNull: false,
  )


  final String? ref;



  @JsonKey(
    
    name: r'self_hosting',
    required: false,
    includeIfNull: false,
  )


  final bool? selfHosting;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdmitWaitlistRequest &&
      other.ids == ids &&
      other.count == count &&
      other.source_ == source_ &&
      other.ref == ref &&
      other.selfHosting == selfHosting;

    @override
    int get hashCode =>
        ids.hashCode +
        count.hashCode +
        source_.hashCode +
        ref.hashCode +
        selfHosting.hashCode;

  factory AdmitWaitlistRequest.fromJson(Map<String, dynamic> json) => _$AdmitWaitlistRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdmitWaitlistRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/waitlist_proof.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'join_waitlist_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class JoinWaitlistRequest {
  /// Returns a new [JoinWaitlistRequest] instance.
  JoinWaitlistRequest({

    required  this.email,

    required  this.proof,

     this.source_,

     this.ref,

     this.note,

     this.selfHosting,

     this.newsletter,
  });

  @JsonKey(
    
    name: r'email',
    required: true,
    includeIfNull: false,
  )


  final String email;



  @JsonKey(
    
    name: r'proof',
    required: true,
    includeIfNull: false,
  )


  final WaitlistProof proof;



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
    
    name: r'note',
    required: false,
    includeIfNull: false,
  )


  final String? note;



  @JsonKey(
    
    name: r'self_hosting',
    required: false,
    includeIfNull: false,
  )


  final bool? selfHosting;



  @JsonKey(
    
    name: r'newsletter',
    required: false,
    includeIfNull: false,
  )


  final bool? newsletter;





    @override
    bool operator ==(Object other) => identical(this, other) || other is JoinWaitlistRequest &&
      other.email == email &&
      other.proof == proof &&
      other.source_ == source_ &&
      other.ref == ref &&
      other.note == note &&
      other.selfHosting == selfHosting &&
      other.newsletter == newsletter;

    @override
    int get hashCode =>
        email.hashCode +
        proof.hashCode +
        source_.hashCode +
        ref.hashCode +
        note.hashCode +
        selfHosting.hashCode +
        newsletter.hashCode;

  factory JoinWaitlistRequest.fromJson(Map<String, dynamic> json) => _$JoinWaitlistRequestFromJson(json);

  Map<String, dynamic> toJson() => _$JoinWaitlistRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


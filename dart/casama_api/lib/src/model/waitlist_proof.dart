//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'waitlist_proof.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WaitlistProof {
  /// Returns a new [WaitlistProof] instance.
  WaitlistProof({

    required  this.challenge,

    required  this.nonce,
  });

  @JsonKey(
    
    name: r'challenge',
    required: true,
    includeIfNull: false,
  )


  final String challenge;



  @JsonKey(
    
    name: r'nonce',
    required: true,
    includeIfNull: false,
  )


  final String nonce;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WaitlistProof &&
      other.challenge == challenge &&
      other.nonce == nonce;

    @override
    int get hashCode =>
        challenge.hashCode +
        nonce.hashCode;

  factory WaitlistProof.fromJson(Map<String, dynamic> json) => _$WaitlistProofFromJson(json);

  Map<String, dynamic> toJson() => _$WaitlistProofToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


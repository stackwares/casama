//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'referral_invites.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReferralInvites {
  /// Returns a new [ReferralInvites] instance.
  ReferralInvites({

    required  this.total,

    required  this.used,

    required  this.left,

    required  this.unlocked,
  });

  @JsonKey(
    
    name: r'total',
    required: true,
    includeIfNull: false,
  )


  final int total;



  @JsonKey(
    
    name: r'used',
    required: true,
    includeIfNull: false,
  )


  final int used;



  @JsonKey(
    
    name: r'left',
    required: true,
    includeIfNull: false,
  )


  final int left;



  @JsonKey(
    
    name: r'unlocked',
    required: true,
    includeIfNull: false,
  )


  final bool unlocked;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReferralInvites &&
      other.total == total &&
      other.used == used &&
      other.left == left &&
      other.unlocked == unlocked;

    @override
    int get hashCode =>
        total.hashCode +
        used.hashCode +
        left.hashCode +
        unlocked.hashCode;

  factory ReferralInvites.fromJson(Map<String, dynamic> json) => _$ReferralInvitesFromJson(json);

  Map<String, dynamic> toJson() => _$ReferralInvitesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


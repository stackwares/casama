//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invite_redeemed.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InviteRedeemed {
  /// Returns a new [InviteRedeemed] instance.
  InviteRedeemed({

    required  this.outcome,

    required  this.kind,
  });

  @JsonKey(
    
    name: r'outcome',
    required: true,
    includeIfNull: false,
  )


  final InviteRedeemedOutcomeEnum outcome;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final InviteRedeemedKindEnum kind;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InviteRedeemed &&
      other.outcome == outcome &&
      other.kind == kind;

    @override
    int get hashCode =>
        outcome.hashCode +
        kind.hashCode;

  factory InviteRedeemed.fromJson(Map<String, dynamic> json) => _$InviteRedeemedFromJson(json);

  Map<String, dynamic> toJson() => _$InviteRedeemedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum InviteRedeemedOutcomeEnum {
@JsonValue(r'admitted')
admitted(r'admitted'),
@JsonValue(r'waitlisted')
waitlisted(r'waitlisted');

const InviteRedeemedOutcomeEnum(this.value);

final String value;

@override
String toString() => value;
}



enum InviteRedeemedKindEnum {
@JsonValue(r'personal')
personal(r'personal'),
@JsonValue(r'campaign')
campaign(r'campaign'),
@JsonValue(r'one_time')
oneTime(r'one_time');

const InviteRedeemedKindEnum(this.value);

final String value;

@override
String toString() => value;
}



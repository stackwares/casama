//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'comp.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Comp {
  /// Returns a new [Comp] instance.
  Comp({

    required  this.id,

    required  this.orgId,

    required  this.orgName,

    required  this.userId,

    required  this.email,

    required  this.planCode,

    required  this.months,

    required  this.startsAt,

    required  this.endsAt,

    required  this.from,

    required  this.codeId,

    required  this.note,

    required  this.endedAt,

    required  this.endReason,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'org_name',
    required: true,
    includeIfNull: true,
  )


  final String? orgName;



  @JsonKey(
    
    name: r'user_id',
    required: true,
    includeIfNull: true,
  )


  final String? userId;



      /// Masked, like fr••••@example.com
  @JsonKey(
    
    name: r'email',
    required: true,
    includeIfNull: true,
  )


  final String? email;



  @JsonKey(
    
    name: r'plan_code',
    required: true,
    includeIfNull: false,
  )


  final String planCode;



  @JsonKey(
    
    name: r'months',
    required: true,
    includeIfNull: false,
  )


  final int months;



  @JsonKey(
    
    name: r'starts_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime startsAt;



  @JsonKey(
    
    name: r'ends_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime endsAt;



  @JsonKey(
    
    name: r'from',
    required: true,
    includeIfNull: false,
  )


  final CompFromEnum from;



  @JsonKey(
    
    name: r'code_id',
    required: true,
    includeIfNull: true,
  )


  final String? codeId;



  @JsonKey(
    
    name: r'note',
    required: true,
    includeIfNull: true,
  )


  final String? note;



  @JsonKey(
    
    name: r'ended_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? endedAt;



      /// expired, revoked or replaced_by_purchase; null while it runs
  @JsonKey(
    
    name: r'end_reason',
    required: true,
    includeIfNull: true,
  )


  final String? endReason;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Comp &&
      other.id == id &&
      other.orgId == orgId &&
      other.orgName == orgName &&
      other.userId == userId &&
      other.email == email &&
      other.planCode == planCode &&
      other.months == months &&
      other.startsAt == startsAt &&
      other.endsAt == endsAt &&
      other.from == from &&
      other.codeId == codeId &&
      other.note == note &&
      other.endedAt == endedAt &&
      other.endReason == endReason &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        (orgName == null ? 0 : orgName.hashCode) +
        (userId == null ? 0 : userId.hashCode) +
        (email == null ? 0 : email.hashCode) +
        planCode.hashCode +
        months.hashCode +
        startsAt.hashCode +
        endsAt.hashCode +
        from.hashCode +
        (codeId == null ? 0 : codeId.hashCode) +
        (note == null ? 0 : note.hashCode) +
        (endedAt == null ? 0 : endedAt.hashCode) +
        (endReason == null ? 0 : endReason.hashCode) +
        createdAt.hashCode;

  factory Comp.fromJson(Map<String, dynamic> json) => _$CompFromJson(json);

  Map<String, dynamic> toJson() => _$CompToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CompFromEnum {
@JsonValue(r'grant')
grant(r'grant'),
@JsonValue(r'code')
code(r'code');

const CompFromEnum(this.value);

final String value;

@override
String toString() => value;
}



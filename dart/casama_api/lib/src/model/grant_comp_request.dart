//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'grant_comp_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GrantCompRequest {
  /// Returns a new [GrantCompRequest] instance.
  GrantCompRequest({

     this.email,

     this.userId,

     this.orgId,

    required  this.planCode,

    required  this.months,

     this.note,
  });

  @JsonKey(
    
    name: r'email',
    required: false,
    includeIfNull: false,
  )


  final String? email;



  @JsonKey(
    
    name: r'user_id',
    required: false,
    includeIfNull: false,
  )


  final String? userId;



      /// The workspace; default: the oldest one the person owns
  @JsonKey(
    
    name: r'org_id',
    required: false,
    includeIfNull: false,
  )


  final String? orgId;



  @JsonKey(
    
    name: r'plan_code',
    required: true,
    includeIfNull: false,
  )


  final String planCode;



          // minimum: 1
          // maximum: 36
  @JsonKey(
    
    name: r'months',
    required: true,
    includeIfNull: false,
  )


  final int months;



  @JsonKey(
    
    name: r'note',
    required: false,
    includeIfNull: false,
  )


  final String? note;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GrantCompRequest &&
      other.email == email &&
      other.userId == userId &&
      other.orgId == orgId &&
      other.planCode == planCode &&
      other.months == months &&
      other.note == note;

    @override
    int get hashCode =>
        email.hashCode +
        userId.hashCode +
        orgId.hashCode +
        planCode.hashCode +
        months.hashCode +
        (note == null ? 0 : note.hashCode);

  factory GrantCompRequest.fromJson(Map<String, dynamic> json) => _$GrantCompRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GrantCompRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


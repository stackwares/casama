//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/organization_with_role.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'join_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class JoinResult {
  /// Returns a new [JoinResult] instance.
  JoinResult({

    required  this.status,

     this.organization,

    required  this.workspaceName,
  });

  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final JoinResultStatusEnum status;



  @JsonKey(
    
    name: r'organization',
    required: false,
    includeIfNull: false,
  )


  final OrganizationWithRole? organization;



  @JsonKey(
    
    name: r'workspace_name',
    required: true,
    includeIfNull: false,
  )


  final String workspaceName;





    @override
    bool operator ==(Object other) => identical(this, other) || other is JoinResult &&
      other.status == status &&
      other.organization == organization &&
      other.workspaceName == workspaceName;

    @override
    int get hashCode =>
        status.hashCode +
        organization.hashCode +
        workspaceName.hashCode;

  factory JoinResult.fromJson(Map<String, dynamic> json) => _$JoinResultFromJson(json);

  Map<String, dynamic> toJson() => _$JoinResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum JoinResultStatusEnum {
@JsonValue(r'joined')
joined(r'joined'),
@JsonValue(r'member')
member(r'member'),
@JsonValue(r'requested')
requested(r'requested');

const JoinResultStatusEnum(this.value);

final String value;

@override
String toString() => value;
}



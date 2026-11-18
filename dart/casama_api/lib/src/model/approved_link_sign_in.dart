//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'approved_link_sign_in.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApprovedLinkSignIn {
  /// Returns a new [ApprovedLinkSignIn] instance.
  ApprovedLinkSignIn({

    required  this.instanceName,
  });

  @JsonKey(
    
    name: r'instance_name',
    required: true,
    includeIfNull: false,
  )


  final String instanceName;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ApprovedLinkSignIn &&
      other.instanceName == instanceName;

    @override
    int get hashCode =>
        instanceName.hashCode;

  factory ApprovedLinkSignIn.fromJson(Map<String, dynamic> json) => _$ApprovedLinkSignInFromJson(json);

  Map<String, dynamic> toJson() => _$ApprovedLinkSignInToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


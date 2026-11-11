//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_user.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminUser {
  /// Returns a new [AdminUser] instance.
  AdminUser({

    required  this.id,

    required  this.email,

    required  this.createdAt,

    required  this.lastSignInAt,

    required  this.orgs,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'email',
    required: true,
    includeIfNull: true,
  )


  final String? email;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'last_sign_in_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? lastSignInAt;



  @JsonKey(
    
    name: r'orgs',
    required: true,
    includeIfNull: false,
  )


  final int orgs;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminUser &&
      other.id == id &&
      other.email == email &&
      other.createdAt == createdAt &&
      other.lastSignInAt == lastSignInAt &&
      other.orgs == orgs;

    @override
    int get hashCode =>
        id.hashCode +
        (email == null ? 0 : email.hashCode) +
        createdAt.hashCode +
        (lastSignInAt == null ? 0 : lastSignInAt.hashCode) +
        orgs.hashCode;

  factory AdminUser.fromJson(Map<String, dynamic> json) => _$AdminUserFromJson(json);

  Map<String, dynamic> toJson() => _$AdminUserToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


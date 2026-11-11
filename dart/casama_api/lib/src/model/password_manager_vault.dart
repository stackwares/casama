//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'password_manager_vault.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PasswordManagerVault {
  /// Returns a new [PasswordManagerVault] instance.
  PasswordManagerVault({

    required  this.id,

    required  this.name,

    required  this.allowed,

    required  this.logins,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'allowed',
    required: true,
    includeIfNull: false,
  )


  final bool allowed;



  @JsonKey(
    
    name: r'logins',
    required: true,
    includeIfNull: true,
  )


  final int? logins;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PasswordManagerVault &&
      other.id == id &&
      other.name == name &&
      other.allowed == allowed &&
      other.logins == logins;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        allowed.hashCode +
        (logins == null ? 0 : logins.hashCode);

  factory PasswordManagerVault.fromJson(Map<String, dynamic> json) => _$PasswordManagerVaultFromJson(json);

  Map<String, dynamic> toJson() => _$PasswordManagerVaultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


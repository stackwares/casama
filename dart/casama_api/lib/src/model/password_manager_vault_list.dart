//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/password_manager_vault.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'password_manager_vault_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PasswordManagerVaultList {
  /// Returns a new [PasswordManagerVaultList] instance.
  PasswordManagerVaultList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<PasswordManagerVault> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PasswordManagerVaultList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory PasswordManagerVaultList.fromJson(Map<String, dynamic> json) => _$PasswordManagerVaultListFromJson(json);

  Map<String, dynamic> toJson() => _$PasswordManagerVaultListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


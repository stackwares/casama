//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/password_manager.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'password_manager_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PasswordManagerList {
  /// Returns a new [PasswordManagerList] instance.
  PasswordManagerList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<PasswordManager> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PasswordManagerList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory PasswordManagerList.fromJson(Map<String, dynamic> json) => _$PasswordManagerListFromJson(json);

  Map<String, dynamic> toJson() => _$PasswordManagerListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


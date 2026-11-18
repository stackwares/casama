//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/admin_user.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_user_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminUserList {
  /// Returns a new [AdminUserList] instance.
  AdminUserList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<AdminUser> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminUserList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory AdminUserList.fromJson(Map<String, dynamic> json) => _$AdminUserListFromJson(json);

  Map<String, dynamic> toJson() => _$AdminUserListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


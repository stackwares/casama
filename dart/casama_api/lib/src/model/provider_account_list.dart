//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/provider_account.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'provider_account_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProviderAccountList {
  /// Returns a new [ProviderAccountList] instance.
  ProviderAccountList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<ProviderAccount> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ProviderAccountList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ProviderAccountList.fromJson(Map<String, dynamic> json) => _$ProviderAccountListFromJson(json);

  Map<String, dynamic> toJson() => _$ProviderAccountListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


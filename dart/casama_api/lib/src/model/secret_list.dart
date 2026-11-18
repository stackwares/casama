//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/secret.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'secret_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SecretList {
  /// Returns a new [SecretList] instance.
  SecretList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Secret> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SecretList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory SecretList.fromJson(Map<String, dynamic> json) => _$SecretListFromJson(json);

  Map<String, dynamic> toJson() => _$SecretListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


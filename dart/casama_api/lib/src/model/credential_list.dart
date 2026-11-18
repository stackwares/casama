//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/credential.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'credential_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CredentialList {
  /// Returns a new [CredentialList] instance.
  CredentialList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Credential> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CredentialList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory CredentialList.fromJson(Map<String, dynamic> json) => _$CredentialListFromJson(json);

  Map<String, dynamic> toJson() => _$CredentialListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


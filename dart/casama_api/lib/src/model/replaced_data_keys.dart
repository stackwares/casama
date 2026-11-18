//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'replaced_data_keys.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReplacedDataKeys {
  /// Returns a new [ReplacedDataKeys] instance.
  ReplacedDataKeys({

    required  this.workspaces,

    required  this.people,
  });

  @JsonKey(
    
    name: r'workspaces',
    required: true,
    includeIfNull: false,
  )


  final int workspaces;



  @JsonKey(
    
    name: r'people',
    required: true,
    includeIfNull: false,
  )


  final int people;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReplacedDataKeys &&
      other.workspaces == workspaces &&
      other.people == people;

    @override
    int get hashCode =>
        workspaces.hashCode +
        people.hashCode;

  factory ReplacedDataKeys.fromJson(Map<String, dynamic> json) => _$ReplacedDataKeysFromJson(json);

  Map<String, dynamic> toJson() => _$ReplacedDataKeysToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/reported_creation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reported_creation_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportedCreationList {
  /// Returns a new [ReportedCreationList] instance.
  ReportedCreationList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<ReportedCreation> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReportedCreationList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ReportedCreationList.fromJson(Map<String, dynamic> json) => _$ReportedCreationListFromJson(json);

  Map<String, dynamic> toJson() => _$ReportedCreationListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


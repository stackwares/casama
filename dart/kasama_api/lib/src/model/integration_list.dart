//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/integration.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'integration_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class IntegrationList {
  /// Returns a new [IntegrationList] instance.
  IntegrationList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Integration> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is IntegrationList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory IntegrationList.fromJson(Map<String, dynamic> json) => _$IntegrationListFromJson(json);

  Map<String, dynamic> toJson() => _$IntegrationListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


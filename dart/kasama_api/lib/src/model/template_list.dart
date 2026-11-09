//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/template.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'template_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TemplateList {
  /// Returns a new [TemplateList] instance.
  TemplateList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Template> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TemplateList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory TemplateList.fromJson(Map<String, dynamic> json) => _$TemplateListFromJson(json);

  Map<String, dynamic> toJson() => _$TemplateListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


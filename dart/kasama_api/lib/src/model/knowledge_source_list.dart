//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/knowledge_source.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'knowledge_source_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class KnowledgeSourceList {
  /// Returns a new [KnowledgeSourceList] instance.
  KnowledgeSourceList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<KnowledgeSource> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is KnowledgeSourceList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory KnowledgeSourceList.fromJson(Map<String, dynamic> json) => _$KnowledgeSourceListFromJson(json);

  Map<String, dynamic> toJson() => _$KnowledgeSourceListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


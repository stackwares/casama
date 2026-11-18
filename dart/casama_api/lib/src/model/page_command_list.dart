//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/page_command.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'page_command_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PageCommandList {
  /// Returns a new [PageCommandList] instance.
  PageCommandList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<PageCommand> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PageCommandList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory PageCommandList.fromJson(Map<String, dynamic> json) => _$PageCommandListFromJson(json);

  Map<String, dynamic> toJson() => _$PageCommandListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


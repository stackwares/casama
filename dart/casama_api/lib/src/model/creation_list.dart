//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/creation.dart';
import 'package:casama_api/src/model/creation_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'creation_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreationList {
  /// Returns a new [CreationList] instance.
  CreationList({

    required  this.items,

    required  this.nextCursor,

    required  this.kinds,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Creation> items;



      /// Pass back as cursor for more
  @JsonKey(
    
    name: r'next_cursor',
    required: true,
    includeIfNull: true,
  )


  final String? nextCursor;



      /// The kinds this workspace has, for filter chips
  @JsonKey(
    
    name: r'kinds',
    required: true,
    includeIfNull: false,
  )


  final List<CreationKind> kinds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreationList &&
      other.items == items &&
      other.nextCursor == nextCursor &&
      other.kinds == kinds;

    @override
    int get hashCode =>
        items.hashCode +
        (nextCursor == null ? 0 : nextCursor.hashCode) +
        kinds.hashCode;

  factory CreationList.fromJson(Map<String, dynamic> json) => _$CreationListFromJson(json);

  Map<String, dynamic> toJson() => _$CreationListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


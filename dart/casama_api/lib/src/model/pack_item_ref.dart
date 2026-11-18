//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/pack_item_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_item_ref.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackItemRef {
  /// Returns a new [PackItemRef] instance.
  PackItemRef({

    required  this.kind,

    required  this.id,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final PackItemKind kind;



  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackItemRef &&
      other.kind == kind &&
      other.id == id;

    @override
    int get hashCode =>
        kind.hashCode +
        id.hashCode;

  factory PackItemRef.fromJson(Map<String, dynamic> json) => _$PackItemRefFromJson(json);

  Map<String, dynamic> toJson() => _$PackItemRefToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


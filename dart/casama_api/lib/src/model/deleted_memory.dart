//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'deleted_memory.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeletedMemory {
  /// Returns a new [DeletedMemory] instance.
  DeletedMemory({

    required  this.deleted,
  });

  @JsonKey(
    
    name: r'deleted',
    required: true,
    includeIfNull: false,
  )


  final String deleted;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeletedMemory &&
      other.deleted == deleted;

    @override
    int get hashCode =>
        deleted.hashCode;

  factory DeletedMemory.fromJson(Map<String, dynamic> json) => _$DeletedMemoryFromJson(json);

  Map<String, dynamic> toJson() => _$DeletedMemoryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


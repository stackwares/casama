//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'storage_category.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StorageCategory {
  /// Returns a new [StorageCategory] instance.
  StorageCategory({

    required  this.id,

    required  this.bytes,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final StorageCategoryIdEnum id;



  @JsonKey(
    
    name: r'bytes',
    required: true,
    includeIfNull: false,
  )


  final int bytes;





    @override
    bool operator ==(Object other) => identical(this, other) || other is StorageCategory &&
      other.id == id &&
      other.bytes == bytes;

    @override
    int get hashCode =>
        id.hashCode +
        bytes.hashCode;

  factory StorageCategory.fromJson(Map<String, dynamic> json) => _$StorageCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$StorageCategoryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum StorageCategoryIdEnum {
@JsonValue(r'files')
files(r'files'),
@JsonValue(r'apps')
apps(r'apps'),
@JsonValue(r'caches')
caches(r'caches'),
@JsonValue(r'browser')
browser(r'browser'),
@JsonValue(r'other')
other(r'other');

const StorageCategoryIdEnum(this.value);

final String value;

@override
String toString() => value;
}



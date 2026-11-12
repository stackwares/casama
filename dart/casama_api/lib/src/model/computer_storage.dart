//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/storage_category.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'computer_storage.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComputerStorage {
  /// Returns a new [ComputerStorage] instance.
  ComputerStorage({

    required  this.usedBytes,

    required  this.limitBytes,

    required  this.categories,

    required  this.cleanableBytes,
  });

  @JsonKey(
    
    name: r'used_bytes',
    required: true,
    includeIfNull: false,
  )


  final int usedBytes;



  @JsonKey(
    
    name: r'limit_bytes',
    required: true,
    includeIfNull: false,
  )


  final int limitBytes;



  @JsonKey(
    
    name: r'categories',
    required: true,
    includeIfNull: false,
  )


  final List<StorageCategory> categories;



      /// Caches and temporary files that Free up space removes
  @JsonKey(
    
    name: r'cleanable_bytes',
    required: true,
    includeIfNull: false,
  )


  final int cleanableBytes;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ComputerStorage &&
      other.usedBytes == usedBytes &&
      other.limitBytes == limitBytes &&
      other.categories == categories &&
      other.cleanableBytes == cleanableBytes;

    @override
    int get hashCode =>
        usedBytes.hashCode +
        limitBytes.hashCode +
        categories.hashCode +
        cleanableBytes.hashCode;

  factory ComputerStorage.fromJson(Map<String, dynamic> json) => _$ComputerStorageFromJson(json);

  Map<String, dynamic> toJson() => _$ComputerStorageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


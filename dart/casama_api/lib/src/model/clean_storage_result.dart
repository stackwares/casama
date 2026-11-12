//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/computer_storage.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'clean_storage_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CleanStorageResult {
  /// Returns a new [CleanStorageResult] instance.
  CleanStorageResult({

    required  this.freedBytes,

    required  this.storage,
  });

  @JsonKey(
    
    name: r'freed_bytes',
    required: true,
    includeIfNull: false,
  )


  final int freedBytes;



  @JsonKey(
    
    name: r'storage',
    required: true,
    includeIfNull: false,
  )


  final ComputerStorage storage;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CleanStorageResult &&
      other.freedBytes == freedBytes &&
      other.storage == storage;

    @override
    int get hashCode =>
        freedBytes.hashCode +
        storage.hashCode;

  factory CleanStorageResult.fromJson(Map<String, dynamic> json) => _$CleanStorageResultFromJson(json);

  Map<String, dynamic> toJson() => _$CleanStorageResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


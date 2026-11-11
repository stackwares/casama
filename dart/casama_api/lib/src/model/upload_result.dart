//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'upload_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UploadResult {
  /// Returns a new [UploadResult] instance.
  UploadResult({

    required  this.path,

    required  this.size,
  });

  @JsonKey(
    
    name: r'path',
    required: true,
    includeIfNull: false,
  )


  final String path;



  @JsonKey(
    
    name: r'size',
    required: true,
    includeIfNull: false,
  )


  final int size;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UploadResult &&
      other.path == path &&
      other.size == size;

    @override
    int get hashCode =>
        path.hashCode +
        size.hashCode;

  factory UploadResult.fromJson(Map<String, dynamic> json) => _$UploadResultFromJson(json);

  Map<String, dynamic> toJson() => _$UploadResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_file_input.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackFileInput {
  /// Returns a new [PackFileInput] instance.
  PackFileInput({

    required  this.path,

    required  this.base64,

     this.executable,
  });

  @JsonKey(
    
    name: r'path',
    required: true,
    includeIfNull: false,
  )


  final String path;



  @JsonKey(
    
    name: r'base64',
    required: true,
    includeIfNull: false,
  )


  final String base64;



  @JsonKey(
    
    name: r'executable',
    required: false,
    includeIfNull: false,
  )


  final bool? executable;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackFileInput &&
      other.path == path &&
      other.base64 == base64 &&
      other.executable == executable;

    @override
    int get hashCode =>
        path.hashCode +
        base64.hashCode +
        executable.hashCode;

  factory PackFileInput.fromJson(Map<String, dynamic> json) => _$PackFileInputFromJson(json);

  Map<String, dynamic> toJson() => _$PackFileInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


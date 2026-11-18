//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_export_file.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackExportFile {
  /// Returns a new [PackExportFile] instance.
  PackExportFile({

    required  this.path,

    required  this.text,

    required  this.base64,

    required  this.executable,
  });

  @JsonKey(
    
    name: r'path',
    required: true,
    includeIfNull: false,
  )


  final String path;



  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: true,
  )


  final String? text;



  @JsonKey(
    
    name: r'base64',
    required: true,
    includeIfNull: true,
  )


  final String? base64;



  @JsonKey(
    
    name: r'executable',
    required: true,
    includeIfNull: false,
  )


  final bool executable;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackExportFile &&
      other.path == path &&
      other.text == text &&
      other.base64 == base64 &&
      other.executable == executable;

    @override
    int get hashCode =>
        path.hashCode +
        (text == null ? 0 : text.hashCode) +
        (base64 == null ? 0 : base64.hashCode) +
        executable.hashCode;

  factory PackExportFile.fromJson(Map<String, dynamic> json) => _$PackExportFileFromJson(json);

  Map<String, dynamic> toJson() => _$PackExportFileToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'skill_preview_file.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SkillPreviewFile {
  /// Returns a new [SkillPreviewFile] instance.
  SkillPreviewFile({

    required  this.path,

    required  this.size,

    required  this.executable,

    required  this.text,
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



  @JsonKey(
    
    name: r'executable',
    required: true,
    includeIfNull: false,
  )


  final bool executable;



      /// Contents of text files up to 100 KB; null for binaries
  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: true,
  )


  final String? text;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SkillPreviewFile &&
      other.path == path &&
      other.size == size &&
      other.executable == executable &&
      other.text == text;

    @override
    int get hashCode =>
        path.hashCode +
        size.hashCode +
        executable.hashCode +
        (text == null ? 0 : text.hashCode);

  factory SkillPreviewFile.fromJson(Map<String, dynamic> json) => _$SkillPreviewFileFromJson(json);

  Map<String, dynamic> toJson() => _$SkillPreviewFileToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


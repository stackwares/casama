//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'paste_import_prompt.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PasteImportPrompt {
  /// Returns a new [PasteImportPrompt] instance.
  PasteImportPrompt({

    required  this.prompt,

    required  this.version,
  });

  @JsonKey(
    
    name: r'prompt',
    required: true,
    includeIfNull: false,
  )


  final String prompt;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final int version;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PasteImportPrompt &&
      other.prompt == prompt &&
      other.version == version;

    @override
    int get hashCode =>
        prompt.hashCode +
        version.hashCode;

  factory PasteImportPrompt.fromJson(Map<String, dynamic> json) => _$PasteImportPromptFromJson(json);

  Map<String, dynamic> toJson() => _$PasteImportPromptToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'memory_import_prompt.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MemoryImportPrompt {
  /// Returns a new [MemoryImportPrompt] instance.
  MemoryImportPrompt({

    required  this.prompt,
  });

  @JsonKey(
    
    name: r'prompt',
    required: true,
    includeIfNull: false,
  )


  final String prompt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MemoryImportPrompt &&
      other.prompt == prompt;

    @override
    int get hashCode =>
        prompt.hashCode;

  factory MemoryImportPrompt.fromJson(Map<String, dynamic> json) => _$MemoryImportPromptFromJson(json);

  Map<String, dynamic> toJson() => _$MemoryImportPromptToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


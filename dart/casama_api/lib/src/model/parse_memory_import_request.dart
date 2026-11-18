//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'parse_memory_import_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ParseMemoryImportRequest {
  /// Returns a new [ParseMemoryImportRequest] instance.
  ParseMemoryImportRequest({

    required  this.text,
  });

  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ParseMemoryImportRequest &&
      other.text == text;

    @override
    int get hashCode =>
        text.hashCode;

  factory ParseMemoryImportRequest.fromJson(Map<String, dynamic> json) => _$ParseMemoryImportRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ParseMemoryImportRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


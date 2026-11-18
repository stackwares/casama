//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'imported_memory_item.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ImportedMemoryItem {
  /// Returns a new [ImportedMemoryItem] instance.
  ImportedMemoryItem({

    required  this.kind,

    required  this.content,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final ImportedMemoryItemKindEnum kind;



  @JsonKey(
    
    name: r'content',
    required: true,
    includeIfNull: false,
  )


  final String content;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ImportedMemoryItem &&
      other.kind == kind &&
      other.content == content;

    @override
    int get hashCode =>
        kind.hashCode +
        content.hashCode;

  factory ImportedMemoryItem.fromJson(Map<String, dynamic> json) => _$ImportedMemoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$ImportedMemoryItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ImportedMemoryItemKindEnum {
@JsonValue(r'fact')
fact(r'fact'),
@JsonValue(r'preference')
preference(r'preference');

const ImportedMemoryItemKindEnum(this.value);

final String value;

@override
String toString() => value;
}



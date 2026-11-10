//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_template_file_memories_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotTemplateFileMemoriesInner {
  /// Returns a new [BotTemplateFileMemoriesInner] instance.
  BotTemplateFileMemoriesInner({

    required  this.kind,

    required  this.content,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final BotTemplateFileMemoriesInnerKindEnum kind;



  @JsonKey(
    
    name: r'content',
    required: true,
    includeIfNull: false,
  )


  final String content;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotTemplateFileMemoriesInner &&
      other.kind == kind &&
      other.content == content;

    @override
    int get hashCode =>
        kind.hashCode +
        content.hashCode;

  factory BotTemplateFileMemoriesInner.fromJson(Map<String, dynamic> json) => _$BotTemplateFileMemoriesInnerFromJson(json);

  Map<String, dynamic> toJson() => _$BotTemplateFileMemoriesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum BotTemplateFileMemoriesInnerKindEnum {
@JsonValue(r'fact')
fact(r'fact'),
@JsonValue(r'episode')
episode(r'episode'),
@JsonValue(r'summary')
summary(r'summary'),
@JsonValue(r'preference')
preference(r'preference');

const BotTemplateFileMemoriesInnerKindEnum(this.value);

final String value;

@override
String toString() => value;
}



//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_template_file_connections_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotTemplateFileConnectionsInner {
  /// Returns a new [BotTemplateFileConnectionsInner] instance.
  BotTemplateFileConnectionsInner({

    required  this.kind,

    required  this.name,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final String kind;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotTemplateFileConnectionsInner &&
      other.kind == kind &&
      other.name == name;

    @override
    int get hashCode =>
        kind.hashCode +
        name.hashCode;

  factory BotTemplateFileConnectionsInner.fromJson(Map<String, dynamic> json) => _$BotTemplateFileConnectionsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$BotTemplateFileConnectionsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


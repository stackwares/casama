//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'template_author.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TemplateAuthor {
  /// Returns a new [TemplateAuthor] instance.
  TemplateAuthor({

    required  this.name,

     this.url,

     this.handle,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'url',
    required: false,
    includeIfNull: false,
  )


  final String? url;



  @JsonKey(
    
    name: r'handle',
    required: false,
    includeIfNull: false,
  )


  final String? handle;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TemplateAuthor &&
      other.name == name &&
      other.url == url &&
      other.handle == handle;

    @override
    int get hashCode =>
        name.hashCode +
        url.hashCode +
        handle.hashCode;

  factory TemplateAuthor.fromJson(Map<String, dynamic> json) => _$TemplateAuthorFromJson(json);

  Map<String, dynamic> toJson() => _$TemplateAuthorToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


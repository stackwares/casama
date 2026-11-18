//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'support_source.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SupportSource {
  /// Returns a new [SupportSource] instance.
  SupportSource({

    required  this.title,

    required  this.url,
  });

  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SupportSource &&
      other.title == title &&
      other.url == url;

    @override
    int get hashCode =>
        title.hashCode +
        url.hashCode;

  factory SupportSource.fromJson(Map<String, dynamic> json) => _$SupportSourceFromJson(json);

  Map<String, dynamic> toJson() => _$SupportSourceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


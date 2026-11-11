//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'page_view_link_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PageViewLinkRequest {
  /// Returns a new [PageViewLinkRequest] instance.
  PageViewLinkRequest({

     this.format,
  });

  @JsonKey(
    
    name: r'format',
    required: false,
    includeIfNull: false,
  )


  final PageViewLinkRequestFormatEnum? format;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PageViewLinkRequest &&
      other.format == format;

    @override
    int get hashCode =>
        format.hashCode;

  factory PageViewLinkRequest.fromJson(Map<String, dynamic> json) => _$PageViewLinkRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PageViewLinkRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PageViewLinkRequestFormatEnum {
@JsonValue(r'html')
html(r'html'),
@JsonValue(r'pdf')
pdf(r'pdf');

const PageViewLinkRequestFormatEnum(this.value);

final String value;

@override
String toString() => value;
}



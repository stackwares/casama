//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'redirect_url.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RedirectUrl {
  /// Returns a new [RedirectUrl] instance.
  RedirectUrl({

    required  this.url,
  });

  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RedirectUrl &&
      other.url == url;

    @override
    int get hashCode =>
        url.hashCode;

  factory RedirectUrl.fromJson(Map<String, dynamic> json) => _$RedirectUrlFromJson(json);

  Map<String, dynamic> toJson() => _$RedirectUrlToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


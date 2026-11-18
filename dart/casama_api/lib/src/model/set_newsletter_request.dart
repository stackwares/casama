//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_newsletter_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetNewsletterRequest {
  /// Returns a new [SetNewsletterRequest] instance.
  SetNewsletterRequest({

     this.subscribed,

     this.from,
  });

  @JsonKey(
    
    name: r'subscribed',
    required: false,
    includeIfNull: false,
  )


  final bool? subscribed;



  @JsonKey(
    
    name: r'from',
    required: false,
    includeIfNull: false,
  )


  final SetNewsletterRequestFromEnum? from;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetNewsletterRequest &&
      other.subscribed == subscribed &&
      other.from == from;

    @override
    int get hashCode =>
        subscribed.hashCode +
        from.hashCode;

  factory SetNewsletterRequest.fromJson(Map<String, dynamic> json) => _$SetNewsletterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetNewsletterRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SetNewsletterRequestFromEnum {
@JsonValue(r'settings')
settings(r'settings'),
@JsonValue(r'signup')
signup(r'signup'),
@JsonValue(r'card')
card(r'card');

const SetNewsletterRequestFromEnum(this.value);

final String value;

@override
String toString() => value;
}



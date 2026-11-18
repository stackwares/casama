//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'widget_push_token.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WidgetPushToken {
  /// Returns a new [WidgetPushToken] instance.
  WidgetPushToken({

    required  this.token,

    required  this.kind,

     this.sandbox,
  });

  @JsonKey(
    
    name: r'token',
    required: true,
    includeIfNull: false,
  )


  final String token;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final WidgetPushTokenKindEnum kind;



  @JsonKey(
    
    name: r'sandbox',
    required: false,
    includeIfNull: false,
  )


  final bool? sandbox;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WidgetPushToken &&
      other.token == token &&
      other.kind == kind &&
      other.sandbox == sandbox;

    @override
    int get hashCode =>
        token.hashCode +
        kind.hashCode +
        sandbox.hashCode;

  factory WidgetPushToken.fromJson(Map<String, dynamic> json) => _$WidgetPushTokenFromJson(json);

  Map<String, dynamic> toJson() => _$WidgetPushTokenToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum WidgetPushTokenKindEnum {
@JsonValue(r'apns_widgets')
apnsWidgets(r'apns_widgets'),
@JsonValue(r'fcm')
fcm(r'fcm');

const WidgetPushTokenKindEnum(this.value);

final String value;

@override
String toString() => value;
}



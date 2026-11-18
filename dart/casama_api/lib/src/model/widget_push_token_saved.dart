//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'widget_push_token_saved.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WidgetPushTokenSaved {
  /// Returns a new [WidgetPushTokenSaved] instance.
  WidgetPushTokenSaved({

    required  this.ok,
  });

  @JsonKey(
    
    name: r'ok',
    required: true,
    includeIfNull: false,
  )


  final bool ok;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WidgetPushTokenSaved &&
      other.ok == ok;

    @override
    int get hashCode =>
        ok.hashCode;

  factory WidgetPushTokenSaved.fromJson(Map<String, dynamic> json) => _$WidgetPushTokenSavedFromJson(json);

  Map<String, dynamic> toJson() => _$WidgetPushTokenSavedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


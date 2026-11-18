//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'widget_key_update.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WidgetKeyUpdate {
  /// Returns a new [WidgetKeyUpdate] instance.
  WidgetKeyUpdate({

     this.private,
  });

  @JsonKey(
    
    name: r'private',
    required: false,
    includeIfNull: false,
  )


  final bool? private;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WidgetKeyUpdate &&
      other.private == private;

    @override
    int get hashCode =>
        private.hashCode;

  factory WidgetKeyUpdate.fromJson(Map<String, dynamic> json) => _$WidgetKeyUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$WidgetKeyUpdateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


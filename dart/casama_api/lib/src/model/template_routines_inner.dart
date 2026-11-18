//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'template_routines_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TemplateRoutinesInner {
  /// Returns a new [TemplateRoutinesInner] instance.
  TemplateRoutinesInner({

    required  this.name,

    required  this.scheduleCron,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'schedule_cron',
    required: true,
    includeIfNull: false,
  )


  final String scheduleCron;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TemplateRoutinesInner &&
      other.name == name &&
      other.scheduleCron == scheduleCron;

    @override
    int get hashCode =>
        name.hashCode +
        scheduleCron.hashCode;

  factory TemplateRoutinesInner.fromJson(Map<String, dynamic> json) => _$TemplateRoutinesInnerFromJson(json);

  Map<String, dynamic> toJson() => _$TemplateRoutinesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


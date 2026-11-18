//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'widget_key_created.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WidgetKeyCreated {
  /// Returns a new [WidgetKeyCreated] instance.
  WidgetKeyCreated({

    required  this.id,

    required  this.key,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



      /// Shown once
  @JsonKey(
    
    name: r'key',
    required: true,
    includeIfNull: false,
  )


  final String key;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WidgetKeyCreated &&
      other.id == id &&
      other.key == key &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        key.hashCode +
        createdAt.hashCode;

  factory WidgetKeyCreated.fromJson(Map<String, dynamic> json) => _$WidgetKeyCreatedFromJson(json);

  Map<String, dynamic> toJson() => _$WidgetKeyCreatedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


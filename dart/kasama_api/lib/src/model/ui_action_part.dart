//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ui_action_part.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UiActionPart {
  /// Returns a new [UiActionPart] instance.
  UiActionPart({

    required  this.surfaceId,

    required  this.name,

     this.context,
  });

  @JsonKey(
    
    name: r'surface_id',
    required: true,
    includeIfNull: false,
  )


  final String surfaceId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'context',
    required: false,
    includeIfNull: false,
  )


  final Map<String, Object?>? context;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UiActionPart &&
      other.surfaceId == surfaceId &&
      other.name == name &&
      other.context == context;

    @override
    int get hashCode =>
        surfaceId.hashCode +
        name.hashCode +
        context.hashCode;

  factory UiActionPart.fromJson(Map<String, dynamic> json) => _$UiActionPartFromJson(json);

  Map<String, dynamic> toJson() => _$UiActionPartToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


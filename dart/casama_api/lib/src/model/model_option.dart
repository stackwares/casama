//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model_option.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ModelOption {
  /// Returns a new [ModelOption] instance.
  ModelOption({

    required  this.id,

    required  this.name,

     this.contextLength,

     this.featured,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'context_length',
    required: false,
    includeIfNull: false,
  )


  final int? contextLength;



      /// Recommended by Casama; listed first
  @JsonKey(
    
    name: r'featured',
    required: false,
    includeIfNull: false,
  )


  final bool? featured;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ModelOption &&
      other.id == id &&
      other.name == name &&
      other.contextLength == contextLength &&
      other.featured == featured;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        contextLength.hashCode +
        featured.hashCode;

  factory ModelOption.fromJson(Map<String, dynamic> json) => _$ModelOptionFromJson(json);

  Map<String, dynamic> toJson() => _$ModelOptionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


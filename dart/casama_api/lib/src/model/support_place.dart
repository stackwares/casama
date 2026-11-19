//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'support_place.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SupportPlace {
  /// Returns a new [SupportPlace] instance.
  SupportPlace({

    required  this.id,

    required  this.label,

     this.route,

    required  this.url,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: false,
  )


  final String label;



  @JsonKey(
    
    name: r'route',
    required: false,
    includeIfNull: false,
  )


  final String? route;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SupportPlace &&
      other.id == id &&
      other.label == label &&
      other.route == route &&
      other.url == url;

    @override
    int get hashCode =>
        id.hashCode +
        label.hashCode +
        route.hashCode +
        url.hashCode;

  factory SupportPlace.fromJson(Map<String, dynamic> json) => _$SupportPlaceFromJson(json);

  Map<String, dynamic> toJson() => _$SupportPlaceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


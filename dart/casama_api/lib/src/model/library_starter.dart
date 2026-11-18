//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'library_starter.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LibraryStarter {
  /// Returns a new [LibraryStarter] instance.
  LibraryStarter({

    required  this.id,

    required  this.label,

    required  this.prompt,

    required  this.icon,

    required  this.hue,
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



      /// Typed into quick ask; may end in a space
  @JsonKey(
    
    name: r'prompt',
    required: true,
    includeIfNull: false,
  )


  final String prompt;



      /// Lucide icon name; the app falls back to its own
  @JsonKey(
    
    name: r'icon',
    required: true,
    includeIfNull: false,
  )


  final String icon;



  @JsonKey(
    
    name: r'hue',
    required: true,
    includeIfNull: false,
  )


  final num hue;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LibraryStarter &&
      other.id == id &&
      other.label == label &&
      other.prompt == prompt &&
      other.icon == icon &&
      other.hue == hue;

    @override
    int get hashCode =>
        id.hashCode +
        label.hashCode +
        prompt.hashCode +
        icon.hashCode +
        hue.hashCode;

  factory LibraryStarter.fromJson(Map<String, dynamic> json) => _$LibraryStarterFromJson(json);

  Map<String, dynamic> toJson() => _$LibraryStarterToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'text_starter.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TextStarter {
  /// Returns a new [TextStarter] instance.
  TextStarter({

    required  this.id,

    required  this.text,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TextStarter &&
      other.id == id &&
      other.text == text;

    @override
    int get hashCode =>
        id.hashCode +
        text.hashCode;

  factory TextStarter.fromJson(Map<String, dynamic> json) => _$TextStarterFromJson(json);

  Map<String, dynamic> toJson() => _$TextStarterToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


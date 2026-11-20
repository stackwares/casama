//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mail_file.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MailFile {
  /// Returns a new [MailFile] instance.
  MailFile({

    required  this.index,

    required  this.name,

    required  this.mime,

    required  this.size,
  });

  @JsonKey(
    
    name: r'index',
    required: true,
    includeIfNull: false,
  )


  final int index;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'mime',
    required: true,
    includeIfNull: false,
  )


  final String mime;



  @JsonKey(
    
    name: r'size',
    required: true,
    includeIfNull: false,
  )


  final int size;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MailFile &&
      other.index == index &&
      other.name == name &&
      other.mime == mime &&
      other.size == size;

    @override
    int get hashCode =>
        index.hashCode +
        name.hashCode +
        mime.hashCode +
        size.hashCode;

  factory MailFile.fromJson(Map<String, dynamic> json) => _$MailFileFromJson(json);

  Map<String, dynamic> toJson() => _$MailFileToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'import_profile_photo_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ImportProfilePhotoRequest {
  /// Returns a new [ImportProfilePhotoRequest] instance.
  ImportProfilePhotoRequest({

     this.replace,
  });

  @JsonKey(
    
    name: r'replace',
    required: false,
    includeIfNull: false,
  )


  final bool? replace;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ImportProfilePhotoRequest &&
      other.replace == replace;

    @override
    int get hashCode =>
        replace.hashCode;

  factory ImportProfilePhotoRequest.fromJson(Map<String, dynamic> json) => _$ImportProfilePhotoRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ImportProfilePhotoRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


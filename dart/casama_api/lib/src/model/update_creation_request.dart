//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_creation_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateCreationRequest {
  /// Returns a new [UpdateCreationRequest] instance.
  UpdateCreationRequest({

     this.title,

     this.label,

     this.pinned,

     this.opened,

     this.visibility,

     this.expiresInDays,
  });

  @JsonKey(
    
    name: r'title',
    required: false,
    includeIfNull: false,
  )


  final String? title;



  @JsonKey(
    
    name: r'label',
    required: false,
    includeIfNull: false,
  )


  final String? label;



  @JsonKey(
    
    name: r'pinned',
    required: false,
    includeIfNull: false,
  )


  final bool? pinned;



      /// Marks it opened now (Recently opened)
  @JsonKey(
    
    name: r'opened',
    required: false,
    includeIfNull: false,
  )


  final bool? opened;



      /// Making it public returns public_url once; public again gives a new link
  @JsonKey(
    
    name: r'visibility',
    required: false,
    includeIfNull: false,
  )


  final UpdateCreationRequestVisibilityEnum? visibility;



          // minimum: 1
          // maximum: 365
  @JsonKey(
    
    name: r'expires_in_days',
    required: false,
    includeIfNull: false,
  )


  final int? expiresInDays;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateCreationRequest &&
      other.title == title &&
      other.label == label &&
      other.pinned == pinned &&
      other.opened == opened &&
      other.visibility == visibility &&
      other.expiresInDays == expiresInDays;

    @override
    int get hashCode =>
        title.hashCode +
        (label == null ? 0 : label.hashCode) +
        pinned.hashCode +
        opened.hashCode +
        visibility.hashCode +
        expiresInDays.hashCode;

  factory UpdateCreationRequest.fromJson(Map<String, dynamic> json) => _$UpdateCreationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateCreationRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// Making it public returns public_url once; public again gives a new link
enum UpdateCreationRequestVisibilityEnum {
    /// Making it public returns public_url once; public again gives a new link
@JsonValue(r'private')
private(r'private'),
    /// Making it public returns public_url once; public again gives a new link
@JsonValue(r'workspace')
workspace(r'workspace'),
    /// Making it public returns public_url once; public again gives a new link
@JsonValue(r'public')
public(r'public');

const UpdateCreationRequestVisibilityEnum(this.value);

final String value;

@override
String toString() => value;
}



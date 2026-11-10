//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_page_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdatePageRequest {
  /// Returns a new [UpdatePageRequest] instance.
  UpdatePageRequest({

    required  this.visibility,

     this.expiresInDays,
  });

  @JsonKey(
    
    name: r'visibility',
    required: true,
    includeIfNull: false,
  )


  final UpdatePageRequestVisibilityEnum visibility;



          // minimum: 1
          // maximum: 365
  @JsonKey(
    
    name: r'expires_in_days',
    required: false,
    includeIfNull: false,
  )


  final int? expiresInDays;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdatePageRequest &&
      other.visibility == visibility &&
      other.expiresInDays == expiresInDays;

    @override
    int get hashCode =>
        visibility.hashCode +
        expiresInDays.hashCode;

  factory UpdatePageRequest.fromJson(Map<String, dynamic> json) => _$UpdatePageRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdatePageRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum UpdatePageRequestVisibilityEnum {
@JsonValue(r'private')
private(r'private'),
@JsonValue(r'workspace')
workspace(r'workspace'),
@JsonValue(r'public')
public(r'public');

const UpdatePageRequestVisibilityEnum(this.value);

final String value;

@override
String toString() => value;
}



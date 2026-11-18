//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_gallery_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateGalleryRequest {
  /// Returns a new [UpdateGalleryRequest] instance.
  UpdateGalleryRequest({

    required  this.status,

     this.doneItemKey,
  });

  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final UpdateGalleryRequestStatusEnum status;



  @JsonKey(
    
    name: r'done_item_key',
    required: false,
    includeIfNull: false,
  )


  final String? doneItemKey;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateGalleryRequest &&
      other.status == status &&
      other.doneItemKey == doneItemKey;

    @override
    int get hashCode =>
        status.hashCode +
        (doneItemKey == null ? 0 : doneItemKey.hashCode);

  factory UpdateGalleryRequest.fromJson(Map<String, dynamic> json) => _$UpdateGalleryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateGalleryRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum UpdateGalleryRequestStatusEnum {
@JsonValue(r'open')
open(r'open'),
@JsonValue(r'planned')
planned(r'planned'),
@JsonValue(r'done')
done(r'done'),
@JsonValue(r'declined')
declined(r'declined');

const UpdateGalleryRequestStatusEnum(this.value);

final String value;

@override
String toString() => value;
}



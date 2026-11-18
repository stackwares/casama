//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'remove_pack200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RemovePack200Response {
  /// Returns a new [RemovePack200Response] instance.
  RemovePack200Response({

    required  this.deleted,

    required  this.kept,
  });

  @JsonKey(
    
    name: r'deleted',
    required: true,
    includeIfNull: false,
  )


  final String deleted;



  @JsonKey(
    
    name: r'kept',
    required: true,
    includeIfNull: false,
  )


  final int kept;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RemovePack200Response &&
      other.deleted == deleted &&
      other.kept == kept;

    @override
    int get hashCode =>
        deleted.hashCode +
        kept.hashCode;

  factory RemovePack200Response.fromJson(Map<String, dynamic> json) => _$RemovePack200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RemovePack200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


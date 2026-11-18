//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/pack_preview.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_share_view.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackShareView {
  /// Returns a new [PackShareView] instance.
  PackShareView({

    required  this.id,

    required  this.preview,

    required  this.expiresAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'preview',
    required: true,
    includeIfNull: false,
  )


  final PackPreview preview;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackShareView &&
      other.id == id &&
      other.preview == preview &&
      other.expiresAt == expiresAt;

    @override
    int get hashCode =>
        id.hashCode +
        preview.hashCode +
        expiresAt.hashCode;

  factory PackShareView.fromJson(Map<String, dynamic> json) => _$PackShareViewFromJson(json);

  Map<String, dynamic> toJson() => _$PackShareViewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


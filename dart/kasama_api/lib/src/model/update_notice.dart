//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_notice.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateNotice {
  /// Returns a new [UpdateNotice] instance.
  UpdateNotice({

    required  this.current,

    required  this.latest,

    required  this.updateAvailable,

    required  this.url,
  });

  @JsonKey(
    
    name: r'current',
    required: true,
    includeIfNull: false,
  )


  final String current;



  @JsonKey(
    
    name: r'latest',
    required: true,
    includeIfNull: true,
  )


  final String? latest;



  @JsonKey(
    
    name: r'update_available',
    required: true,
    includeIfNull: false,
  )


  final bool updateAvailable;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: true,
  )


  final String? url;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateNotice &&
      other.current == current &&
      other.latest == latest &&
      other.updateAvailable == updateAvailable &&
      other.url == url;

    @override
    int get hashCode =>
        current.hashCode +
        (latest == null ? 0 : latest.hashCode) +
        updateAvailable.hashCode +
        (url == null ? 0 : url.hashCode);

  factory UpdateNotice.fromJson(Map<String, dynamic> json) => _$UpdateNoticeFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateNoticeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


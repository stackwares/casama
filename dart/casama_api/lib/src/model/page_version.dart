//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'page_version.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PageVersion {
  /// Returns a new [PageVersion] instance.
  PageVersion({

    required  this.version,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final int version;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PageVersion &&
      other.version == version &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        version.hashCode +
        createdAt.hashCode;

  factory PageVersion.fromJson(Map<String, dynamic> json) => _$PageVersionFromJson(json);

  Map<String, dynamic> toJson() => _$PageVersionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


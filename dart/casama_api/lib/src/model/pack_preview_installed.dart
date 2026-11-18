//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_preview_installed.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackPreviewInstalled {
  /// Returns a new [PackPreviewInstalled] instance.
  PackPreviewInstalled({

    required  this.id,

    required  this.version,

    required  this.commit,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: true,
  )


  final String? version;



  @JsonKey(
    
    name: r'commit',
    required: true,
    includeIfNull: true,
  )


  final String? commit;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackPreviewInstalled &&
      other.id == id &&
      other.version == version &&
      other.commit == commit;

    @override
    int get hashCode =>
        id.hashCode +
        (version == null ? 0 : version.hashCode) +
        (commit == null ? 0 : commit.hashCode);

  factory PackPreviewInstalled.fromJson(Map<String, dynamic> json) => _$PackPreviewInstalledFromJson(json);

  Map<String, dynamic> toJson() => _$PackPreviewInstalledToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


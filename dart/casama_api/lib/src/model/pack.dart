//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/pack_source.dart';
import 'package:casama_api/src/model/pack_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Pack {
  /// Returns a new [Pack] instance.
  Pack({

    required  this.id,

    required  this.orgId,

    required  this.name,

    required  this.title,

    required  this.version,

    required  this.description,

    required  this.summary,

    required  this.icon,

    required  this.source_,

    required  this.commit,

    required  this.reviewed,

    required  this.items,

    required  this.installedAt,

    required  this.updatedAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



      /// The name people see; `name` is the pack's identity
  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: true,
  )


  final String? version;



  @JsonKey(
    
    name: r'description',
    required: true,
    includeIfNull: false,
  )


  final String description;



  @JsonKey(
    
    name: r'summary',
    required: true,
    includeIfNull: false,
  )


  final String summary;



  @JsonKey(
    
    name: r'icon',
    required: true,
    includeIfNull: false,
  )


  final String icon;



  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final PackSource source_;



  @JsonKey(
    
    name: r'commit',
    required: true,
    includeIfNull: true,
  )


  final String? commit;



  @JsonKey(
    
    name: r'reviewed',
    required: true,
    includeIfNull: false,
  )


  final bool reviewed;



  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<PackItem> items;



  @JsonKey(
    
    name: r'installed_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime installedAt;



  @JsonKey(
    
    name: r'updated_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime updatedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Pack &&
      other.id == id &&
      other.orgId == orgId &&
      other.name == name &&
      other.title == title &&
      other.version == version &&
      other.description == description &&
      other.summary == summary &&
      other.icon == icon &&
      other.source_ == source_ &&
      other.commit == commit &&
      other.reviewed == reviewed &&
      other.items == items &&
      other.installedAt == installedAt &&
      other.updatedAt == updatedAt;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        name.hashCode +
        title.hashCode +
        (version == null ? 0 : version.hashCode) +
        description.hashCode +
        summary.hashCode +
        icon.hashCode +
        source_.hashCode +
        (commit == null ? 0 : commit.hashCode) +
        reviewed.hashCode +
        items.hashCode +
        installedAt.hashCode +
        updatedAt.hashCode;

  factory Pack.fromJson(Map<String, dynamic> json) => _$PackFromJson(json);

  Map<String, dynamic> toJson() => _$PackToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


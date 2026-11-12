//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/content_author.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'directory_plugin.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DirectoryPlugin {
  /// Returns a new [DirectoryPlugin] instance.
  DirectoryPlugin({

    required  this.id,

    required  this.name,

    required  this.description,

    required  this.url,

    required  this.commit,

     this.icon,

    required  this.adds,

    required  this.author,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'description',
    required: true,
    includeIfNull: false,
  )


  final String description;



      /// The plugin's GitHub folder
  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;



      /// The reviewed commit; installing pins it
  @JsonKey(
    
    name: r'commit',
    required: true,
    includeIfNull: false,
  )


  final String commit;



  @JsonKey(
    
    name: r'icon',
    required: false,
    includeIfNull: false,
  )


  final String? icon;



  @JsonKey(
    
    name: r'adds',
    required: true,
    includeIfNull: false,
  )


  final List<String> adds;



  @JsonKey(
    
    name: r'author',
    required: true,
    includeIfNull: false,
  )


  final ContentAuthor author;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DirectoryPlugin &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.url == url &&
      other.commit == commit &&
      other.icon == icon &&
      other.adds == adds &&
      other.author == author;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        description.hashCode +
        url.hashCode +
        commit.hashCode +
        icon.hashCode +
        adds.hashCode +
        author.hashCode;

  factory DirectoryPlugin.fromJson(Map<String, dynamic> json) => _$DirectoryPluginFromJson(json);

  Map<String, dynamic> toJson() => _$DirectoryPluginToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


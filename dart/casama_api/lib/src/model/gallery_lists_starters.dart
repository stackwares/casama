//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/text_starter.dart';
import 'package:casama_api/src/model/library_starter.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_lists_starters.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryListsStarters {
  /// Returns a new [GalleryListsStarters] instance.
  GalleryListsStarters({

     this.library_,

     this.tasks,

     this.support,
  });

  @JsonKey(
    
    name: r'library',
    required: false,
    includeIfNull: false,
  )


  final List<LibraryStarter>? library_;



  @JsonKey(
    
    name: r'tasks',
    required: false,
    includeIfNull: false,
  )


  final List<TextStarter>? tasks;



  @JsonKey(
    
    name: r'support',
    required: false,
    includeIfNull: false,
  )


  final List<TextStarter>? support;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryListsStarters &&
      other.library_ == library_ &&
      other.tasks == tasks &&
      other.support == support;

    @override
    int get hashCode =>
        library_.hashCode +
        tasks.hashCode +
        support.hashCode;

  factory GalleryListsStarters.fromJson(Map<String, dynamic> json) => _$GalleryListsStartersFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryListsStartersToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


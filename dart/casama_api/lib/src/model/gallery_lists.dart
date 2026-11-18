//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_lists_starters.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_lists.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryLists {
  /// Returns a new [GalleryLists] instance.
  GalleryLists({

     this.searchWords,

     this.starters,
  });

      /// Words people use for the same thing, for gallery search
  @JsonKey(
    
    name: r'search_words',
    required: false,
    includeIfNull: false,
  )


  final Map<String, List<String>>? searchWords;



  @JsonKey(
    
    name: r'starters',
    required: false,
    includeIfNull: false,
  )


  final GalleryListsStarters? starters;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryLists &&
      other.searchWords == searchWords &&
      other.starters == starters;

    @override
    int get hashCode =>
        searchWords.hashCode +
        starters.hashCode;

  factory GalleryLists.fromJson(Map<String, dynamic> json) => _$GalleryListsFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryListsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/watch_allow_level.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_prefs.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchPrefs {
  /// Returns a new [WatchPrefs] instance.
  WatchPrefs({

    required  this.allow,

    required  this.showDetails,

    required  this.quickReplies,
  });

  @JsonKey(
    
    name: r'allow',
    required: true,
    includeIfNull: false,
  )


  final WatchAllowLevel allow;



  @JsonKey(
    
    name: r'show_details',
    required: true,
    includeIfNull: false,
  )


  final bool showDetails;



  @JsonKey(
    
    name: r'quick_replies',
    required: true,
    includeIfNull: false,
  )


  final List<String> quickReplies;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchPrefs &&
      other.allow == allow &&
      other.showDetails == showDetails &&
      other.quickReplies == quickReplies;

    @override
    int get hashCode =>
        allow.hashCode +
        showDetails.hashCode +
        quickReplies.hashCode;

  factory WatchPrefs.fromJson(Map<String, dynamic> json) => _$WatchPrefsFromJson(json);

  Map<String, dynamic> toJson() => _$WatchPrefsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


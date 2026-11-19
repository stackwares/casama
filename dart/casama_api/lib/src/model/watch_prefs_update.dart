//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/watch_allow_level.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_prefs_update.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchPrefsUpdate {
  /// Returns a new [WatchPrefsUpdate] instance.
  WatchPrefsUpdate({

     this.allow,

     this.showDetails,

     this.quickReplies,
  });

  @JsonKey(
    
    name: r'allow',
    required: false,
    includeIfNull: false,
  )


  final WatchAllowLevel? allow;



  @JsonKey(
    
    name: r'show_details',
    required: false,
    includeIfNull: false,
  )


  final bool? showDetails;



  @JsonKey(
    
    name: r'quick_replies',
    required: false,
    includeIfNull: false,
  )


  final List<String>? quickReplies;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchPrefsUpdate &&
      other.allow == allow &&
      other.showDetails == showDetails &&
      other.quickReplies == quickReplies;

    @override
    int get hashCode =>
        allow.hashCode +
        showDetails.hashCode +
        (quickReplies == null ? 0 : quickReplies.hashCode);

  factory WatchPrefsUpdate.fromJson(Map<String, dynamic> json) => _$WatchPrefsUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$WatchPrefsUpdateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


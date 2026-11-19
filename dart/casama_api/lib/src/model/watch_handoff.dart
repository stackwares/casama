//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_handoff.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchHandoff {
  /// Returns a new [WatchHandoff] instance.
  WatchHandoff({

    required  this.link,

    required  this.title,
  });

  @JsonKey(
    
    name: r'link',
    required: true,
    includeIfNull: false,
  )


  final String link;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchHandoff &&
      other.link == link &&
      other.title == title;

    @override
    int get hashCode =>
        link.hashCode +
        title.hashCode;

  factory WatchHandoff.fromJson(Map<String, dynamic> json) => _$WatchHandoffFromJson(json);

  Map<String, dynamic> toJson() => _$WatchHandoffToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


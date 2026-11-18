//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_self_saved.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchSelfSaved {
  /// Returns a new [WatchSelfSaved] instance.
  WatchSelfSaved({

    required  this.ok,
  });

  @JsonKey(
    
    name: r'ok',
    required: true,
    includeIfNull: false,
  )


  final bool ok;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchSelfSaved &&
      other.ok == ok;

    @override
    int get hashCode =>
        ok.hashCode;

  factory WatchSelfSaved.fromJson(Map<String, dynamic> json) => _$WatchSelfSavedFromJson(json);

  Map<String, dynamic> toJson() => _$WatchSelfSavedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


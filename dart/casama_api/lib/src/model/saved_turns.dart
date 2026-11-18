//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'saved_turns.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SavedTurns {
  /// Returns a new [SavedTurns] instance.
  SavedTurns({

    required  this.saved,
  });

  @JsonKey(
    
    name: r'saved',
    required: true,
    includeIfNull: false,
  )


  final int saved;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SavedTurns &&
      other.saved == saved;

    @override
    int get hashCode =>
        saved.hashCode;

  factory SavedTurns.fromJson(Map<String, dynamic> json) => _$SavedTurnsFromJson(json);

  Map<String, dynamic> toJson() => _$SavedTurnsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


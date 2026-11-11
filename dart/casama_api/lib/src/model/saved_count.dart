//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'saved_count.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SavedCount {
  /// Returns a new [SavedCount] instance.
  SavedCount({

    required  this.saved,
  });

  @JsonKey(
    
    name: r'saved',
    required: true,
    includeIfNull: false,
  )


  final int saved;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SavedCount &&
      other.saved == saved;

    @override
    int get hashCode =>
        saved.hashCode;

  factory SavedCount.fromJson(Map<String, dynamic> json) => _$SavedCountFromJson(json);

  Map<String, dynamic> toJson() => _$SavedCountToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


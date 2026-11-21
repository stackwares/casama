//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_fares.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchFares {
  /// Returns a new [WatchFares] instance.
  WatchFares({

     this.below,
  });

          // minimum: 0
          // maximum: 10000000
  @JsonKey(
    
    name: r'below',
    required: false,
    includeIfNull: false,
  )


  final num? below;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchFares &&
      other.below == below;

    @override
    int get hashCode =>
        (below == null ? 0 : below.hashCode);

  factory WatchFares.fromJson(Map<String, dynamic> json) => _$WatchFaresFromJson(json);

  Map<String, dynamic> toJson() => _$WatchFaresToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


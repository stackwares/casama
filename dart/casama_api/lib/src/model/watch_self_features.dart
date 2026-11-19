//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_self_features.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchSelfFeatures {
  /// Returns a new [WatchSelfFeatures] instance.
  WatchSelfFeatures({

    required  this.dictation,

    required  this.speech,

    required  this.outOfCredits,
  });

  @JsonKey(
    
    name: r'dictation',
    required: true,
    includeIfNull: false,
  )


  final bool dictation;



  @JsonKey(
    
    name: r'speech',
    required: true,
    includeIfNull: false,
  )


  final bool speech;



  @JsonKey(
    
    name: r'out_of_credits',
    required: true,
    includeIfNull: false,
  )


  final bool outOfCredits;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchSelfFeatures &&
      other.dictation == dictation &&
      other.speech == speech &&
      other.outOfCredits == outOfCredits;

    @override
    int get hashCode =>
        dictation.hashCode +
        speech.hashCode +
        outOfCredits.hashCode;

  factory WatchSelfFeatures.fromJson(Map<String, dynamic> json) => _$WatchSelfFeaturesFromJson(json);

  Map<String, dynamic> toJson() => _$WatchSelfFeaturesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


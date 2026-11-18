//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plugin_pack_summary.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PluginPackSummary {
  /// Returns a new [PluginPackSummary] instance.
  PluginPackSummary({

    required  this.summary,

    required  this.bots,

    required  this.routines,

    required  this.apps,

    required  this.looks,
  });

  @JsonKey(
    
    name: r'summary',
    required: true,
    includeIfNull: false,
  )


  final String summary;



  @JsonKey(
    
    name: r'bots',
    required: true,
    includeIfNull: false,
  )


  final int bots;



  @JsonKey(
    
    name: r'routines',
    required: true,
    includeIfNull: false,
  )


  final int routines;



  @JsonKey(
    
    name: r'apps',
    required: true,
    includeIfNull: false,
  )


  final int apps;



  @JsonKey(
    
    name: r'looks',
    required: true,
    includeIfNull: false,
  )


  final int looks;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PluginPackSummary &&
      other.summary == summary &&
      other.bots == bots &&
      other.routines == routines &&
      other.apps == apps &&
      other.looks == looks;

    @override
    int get hashCode =>
        summary.hashCode +
        bots.hashCode +
        routines.hashCode +
        apps.hashCode +
        looks.hashCode;

  factory PluginPackSummary.fromJson(Map<String, dynamic> json) => _$PluginPackSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$PluginPackSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


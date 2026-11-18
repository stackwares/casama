//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_reach.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackReach {
  /// Returns a new [PackReach] instance.
  PackReach({

    required  this.runsCode,

    required  this.computer,

    required  this.hosts,

    required  this.secrets,

    required  this.settings,

    required  this.runsPerWeek,

    required  this.computers,

     this.knowledgeSources,

     this.knowledgePages,
  });

  @JsonKey(
    
    name: r'runs_code',
    required: true,
    includeIfNull: false,
  )


  final bool runsCode;



  @JsonKey(
    
    name: r'computer',
    required: true,
    includeIfNull: false,
  )


  final bool computer;



  @JsonKey(
    
    name: r'hosts',
    required: true,
    includeIfNull: false,
  )


  final List<String> hosts;



  @JsonKey(
    
    name: r'secrets',
    required: true,
    includeIfNull: false,
  )


  final List<String> secrets;



  @JsonKey(
    
    name: r'settings',
    required: true,
    includeIfNull: false,
  )


  final List<String> settings;



  @JsonKey(
    
    name: r'runs_per_week',
    required: true,
    includeIfNull: false,
  )


  final num runsPerWeek;



  @JsonKey(
    
    name: r'computers',
    required: true,
    includeIfNull: false,
  )


  final int computers;



  @JsonKey(
    
    name: r'knowledge_sources',
    required: false,
    includeIfNull: false,
  )


  final int? knowledgeSources;



      /// Website pages its bots' knowledge reads at most (each sync costs a little)
  @JsonKey(
    
    name: r'knowledge_pages',
    required: false,
    includeIfNull: false,
  )


  final int? knowledgePages;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackReach &&
      other.runsCode == runsCode &&
      other.computer == computer &&
      other.hosts == hosts &&
      other.secrets == secrets &&
      other.settings == settings &&
      other.runsPerWeek == runsPerWeek &&
      other.computers == computers &&
      other.knowledgeSources == knowledgeSources &&
      other.knowledgePages == knowledgePages;

    @override
    int get hashCode =>
        runsCode.hashCode +
        computer.hashCode +
        hosts.hashCode +
        secrets.hashCode +
        settings.hashCode +
        runsPerWeek.hashCode +
        computers.hashCode +
        knowledgeSources.hashCode +
        knowledgePages.hashCode;

  factory PackReach.fromJson(Map<String, dynamic> json) => _$PackReachFromJson(json);

  Map<String, dynamic> toJson() => _$PackReachToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


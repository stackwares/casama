//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/waitlist_entry.dart';
import 'package:casama_api/src/model/waitlist_stats.dart';
import 'package:casama_api/src/model/signup_gate_state.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'waitlist_page.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WaitlistPage {
  /// Returns a new [WaitlistPage] instance.
  WaitlistPage({

    required  this.stats,

    required  this.gate,

    required  this.items,
  });

  @JsonKey(
    
    name: r'stats',
    required: true,
    includeIfNull: false,
  )


  final WaitlistStats stats;



  @JsonKey(
    
    name: r'gate',
    required: true,
    includeIfNull: false,
  )


  final SignupGateState gate;



  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<WaitlistEntry> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WaitlistPage &&
      other.stats == stats &&
      other.gate == gate &&
      other.items == items;

    @override
    int get hashCode =>
        stats.hashCode +
        gate.hashCode +
        items.hashCode;

  factory WaitlistPage.fromJson(Map<String, dynamic> json) => _$WaitlistPageFromJson(json);

  Map<String, dynamic> toJson() => _$WaitlistPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_call_limits.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminCallLimits {
  /// Returns a new [AdminCallLimits] instance.
  AdminCallLimits({

    required  this.limits,

    required  this.builtIn,

    required  this.inUse,

    required  this.ranges,
  });

      /// The values the owner saved; any left out use the default
  @JsonKey(
    
    name: r'limits',
    required: true,
    includeIfNull: false,
  )


  final Map<String, int> limits;



      /// The defaults in code
  @JsonKey(
    
    name: r'built_in',
    required: true,
    includeIfNull: false,
  )


  final Map<String, int> builtIn;



      /// What every process uses now: saved values over the defaults, made to fit together
  @JsonKey(
    
    name: r'in_use',
    required: true,
    includeIfNull: false,
  )


  final Map<String, int> inUse;



      /// The lowest and highest value each limit may take
  @JsonKey(
    
    name: r'ranges',
    required: true,
    includeIfNull: false,
  )


  final Map<String, List<int>> ranges;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminCallLimits &&
      other.limits == limits &&
      other.builtIn == builtIn &&
      other.inUse == inUse &&
      other.ranges == ranges;

    @override
    int get hashCode =>
        limits.hashCode +
        builtIn.hashCode +
        inUse.hashCode +
        ranges.hashCode;

  factory AdminCallLimits.fromJson(Map<String, dynamic> json) => _$AdminCallLimitsFromJson(json);

  Map<String, dynamic> toJson() => _$AdminCallLimitsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'join_domains.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class JoinDomains {
  /// Returns a new [JoinDomains] instance.
  JoinDomains({

    required  this.items,

    required  this.myDomain,

    required  this.canUse,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<String> items;



  @JsonKey(
    
    name: r'my_domain',
    required: true,
    includeIfNull: true,
  )


  final String? myDomain;



  @JsonKey(
    
    name: r'can_use',
    required: true,
    includeIfNull: false,
  )


  final bool canUse;





    @override
    bool operator ==(Object other) => identical(this, other) || other is JoinDomains &&
      other.items == items &&
      other.myDomain == myDomain &&
      other.canUse == canUse;

    @override
    int get hashCode =>
        items.hashCode +
        (myDomain == null ? 0 : myDomain.hashCode) +
        canUse.hashCode;

  factory JoinDomains.fromJson(Map<String, dynamic> json) => _$JoinDomainsFromJson(json);

  Map<String, dynamic> toJson() => _$JoinDomainsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


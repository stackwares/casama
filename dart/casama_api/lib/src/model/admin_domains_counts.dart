//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_domains_counts.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminDomainsCounts {
  /// Returns a new [AdminDomainsCounts] instance.
  AdminDomainsCounts({

    required  this.connected,

    required  this.registered,

    required  this.liveHosts,

    required  this.suspended,
  });

  @JsonKey(
    
    name: r'connected',
    required: true,
    includeIfNull: false,
  )


  final int connected;



  @JsonKey(
    
    name: r'registered',
    required: true,
    includeIfNull: false,
  )


  final int registered;



  @JsonKey(
    
    name: r'live_hosts',
    required: true,
    includeIfNull: false,
  )


  final int liveHosts;



  @JsonKey(
    
    name: r'suspended',
    required: true,
    includeIfNull: false,
  )


  final int suspended;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminDomainsCounts &&
      other.connected == connected &&
      other.registered == registered &&
      other.liveHosts == liveHosts &&
      other.suspended == suspended;

    @override
    int get hashCode =>
        connected.hashCode +
        registered.hashCode +
        liveHosts.hashCode +
        suspended.hashCode;

  factory AdminDomainsCounts.fromJson(Map<String, dynamic> json) => _$AdminDomainsCountsFromJson(json);

  Map<String, dynamic> toJson() => _$AdminDomainsCountsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'browser_guard_sites.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BrowserGuardSites {
  /// Returns a new [BrowserGuardSites] instance.
  BrowserGuardSites({

    required  this.hosts,
  });

      /// Added hosts by kind (banking, health, passwords, government). Kinds this version doesn't know are skipped.
  @JsonKey(
    
    name: r'hosts',
    required: true,
    includeIfNull: false,
  )


  final Map<String, List<String>> hosts;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BrowserGuardSites &&
      other.hosts == hosts;

    @override
    int get hashCode =>
        hosts.hashCode;

  factory BrowserGuardSites.fromJson(Map<String, dynamic> json) => _$BrowserGuardSitesFromJson(json);

  Map<String, dynamic> toJson() => _$BrowserGuardSitesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


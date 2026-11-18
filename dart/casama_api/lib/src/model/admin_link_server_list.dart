//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/admin_link_server.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_link_server_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminLinkServerList {
  /// Returns a new [AdminLinkServerList] instance.
  AdminLinkServerList({

    required  this.items,

    required  this.tunnels,

    required  this.zone,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<AdminLinkServer> items;



      /// Tunnels held at the provider, or null when it didn't answer
  @JsonKey(
    
    name: r'tunnels',
    required: true,
    includeIfNull: true,
  )


  final int? tunnels;



  @JsonKey(
    
    name: r'zone',
    required: true,
    includeIfNull: false,
  )


  final String zone;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminLinkServerList &&
      other.items == items &&
      other.tunnels == tunnels &&
      other.zone == zone;

    @override
    int get hashCode =>
        items.hashCode +
        (tunnels == null ? 0 : tunnels.hashCode) +
        zone.hashCode;

  factory AdminLinkServerList.fromJson(Map<String, dynamic> json) => _$AdminLinkServerListFromJson(json);

  Map<String, dynamic> toJson() => _$AdminLinkServerListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


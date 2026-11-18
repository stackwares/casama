//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'link_server.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LinkServer {
  /// Returns a new [LinkServer] instance.
  LinkServer({

    required  this.id,

    required  this.instanceName,

    required  this.address,

    required  this.pagesAddress,

    required  this.status,

    required  this.statusReason,

    required  this.platform,

    required  this.version,

    required  this.lastSeenAt,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'instance_name',
    required: true,
    includeIfNull: false,
  )


  final String instanceName;



      /// https://<label>.<zone>
  @JsonKey(
    
    name: r'address',
    required: true,
    includeIfNull: false,
  )


  final String address;



  @JsonKey(
    
    name: r'pages_address',
    required: true,
    includeIfNull: false,
  )


  final String pagesAddress;



      /// active: it has a tunnel. parked: not seen for a while, the tunnel returns when the server does. released: remote access was turned off, the address is kept for a time. suspended: taken down. Treat an unknown value as not active.
  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final String status;



  @JsonKey(
    
    name: r'status_reason',
    required: true,
    includeIfNull: true,
  )


  final String? statusReason;



  @JsonKey(
    
    name: r'platform',
    required: true,
    includeIfNull: true,
  )


  final String? platform;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: true,
  )


  final String? version;



  @JsonKey(
    
    name: r'last_seen_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? lastSeenAt;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LinkServer &&
      other.id == id &&
      other.instanceName == instanceName &&
      other.address == address &&
      other.pagesAddress == pagesAddress &&
      other.status == status &&
      other.statusReason == statusReason &&
      other.platform == platform &&
      other.version == version &&
      other.lastSeenAt == lastSeenAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        instanceName.hashCode +
        address.hashCode +
        pagesAddress.hashCode +
        status.hashCode +
        (statusReason == null ? 0 : statusReason.hashCode) +
        (platform == null ? 0 : platform.hashCode) +
        (version == null ? 0 : version.hashCode) +
        (lastSeenAt == null ? 0 : lastSeenAt.hashCode) +
        createdAt.hashCode;

  factory LinkServer.fromJson(Map<String, dynamic> json) => _$LinkServerFromJson(json);

  Map<String, dynamic> toJson() => _$LinkServerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


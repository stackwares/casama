//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'remote_access_status.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RemoteAccessStatus {
  /// Returns a new [RemoteAccessStatus] instance.
  RemoteAccessStatus({

    required  this.state,

    required  this.address,

    required  this.pagesAddress,

    required  this.localAddress,

    required  this.linked,

    required  this.problem,

    required  this.connections,

    required  this.checkedAt,

     this.push,

     this.privateNotifications,

     this.invites,

     this.liveView,
  });

      /// off, starting, online, offline or needs_attention. Treat an unknown value as needs_attention.
  @JsonKey(
    
    name: r'state',
    required: true,
    includeIfNull: false,
  )


  final String state;



      /// The public address, when it is on
  @JsonKey(
    
    name: r'address',
    required: true,
    includeIfNull: true,
  )


  final String? address;



  @JsonKey(
    
    name: r'pages_address',
    required: true,
    includeIfNull: true,
  )


  final String? pagesAddress;



      /// The address on the server's own machine
  @JsonKey(
    
    name: r'local_address',
    required: true,
    includeIfNull: true,
  )


  final String? localAddress;



      /// Whether the server has a link to Casama Cloud
  @JsonKey(
    
    name: r'linked',
    required: true,
    includeIfNull: false,
  )


  final bool linked;



      /// Where it stops: not_linked, cloud_unreachable, key_rejected, suspended, removed, plan_limit, unknown_server, address_changed, connector_missing, connector_blocked (the connector runs but its network blocks the tunnel, outbound port 7844) or address_unanswered (everything looks connected, yet the address doesn't answer from outside). More may be added.
  @JsonKey(
    
    name: r'problem',
    required: true,
    includeIfNull: true,
  )


  final String? problem;



      /// Connections the connector holds; null when it couldn't be asked
  @JsonKey(
    
    name: r'connections',
    required: true,
    includeIfNull: true,
  )


  final int? connections;



  @JsonKey(
    
    name: r'checked_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? checkedAt;



      /// How notifications reach the store apps: own (this server's own Firebase key), relay (through Casama Cloud) or off.
  @JsonKey(
    
    name: r'push',
    required: false,
    includeIfNull: false,
  )


  final String? push;



      /// On: the relay is given no text (the phone shows New activity) and the app loads it from this server.
  @JsonKey(
    
    name: r'private_notifications',
    required: false,
    includeIfNull: false,
  )


  final bool? privateNotifications;



      /// Whether invited people can make an account while remote access is on. Off: sign-ups are closed.
  @JsonKey(
    
    name: r'invites',
    required: false,
    includeIfNull: false,
  )


  final bool? invites;



      /// Live video for people away from the server's machine, which goes through a relay at Casama Cloud: included (the linked workspace's plan has it) or plan (it comes with a higher plan; they see screenshots). Absent when it isn't known. More values may be added.
  @JsonKey(
    
    name: r'live_view',
    required: false,
    includeIfNull: false,
  )


  final String? liveView;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RemoteAccessStatus &&
      other.state == state &&
      other.address == address &&
      other.pagesAddress == pagesAddress &&
      other.localAddress == localAddress &&
      other.linked == linked &&
      other.problem == problem &&
      other.connections == connections &&
      other.checkedAt == checkedAt &&
      other.push == push &&
      other.privateNotifications == privateNotifications &&
      other.invites == invites &&
      other.liveView == liveView;

    @override
    int get hashCode =>
        state.hashCode +
        (address == null ? 0 : address.hashCode) +
        (pagesAddress == null ? 0 : pagesAddress.hashCode) +
        (localAddress == null ? 0 : localAddress.hashCode) +
        linked.hashCode +
        (problem == null ? 0 : problem.hashCode) +
        (connections == null ? 0 : connections.hashCode) +
        (checkedAt == null ? 0 : checkedAt.hashCode) +
        push.hashCode +
        privateNotifications.hashCode +
        invites.hashCode +
        liveView.hashCode;

  factory RemoteAccessStatus.fromJson(Map<String, dynamic> json) => _$RemoteAccessStatusFromJson(json);

  Map<String, dynamic> toJson() => _$RemoteAccessStatusToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


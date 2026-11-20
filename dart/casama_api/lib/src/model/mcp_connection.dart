//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mcp_connection.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class McpConnection {
  /// Returns a new [McpConnection] instance.
  McpConnection({

    required  this.clientId,

    required  this.clientName,

    required  this.userId,

    required  this.userName,

    required  this.mine,

    required  this.connectedAt,

    required  this.lastUsedAt,
  });

  @JsonKey(
    
    name: r'client_id',
    required: true,
    includeIfNull: false,
  )


  final String clientId;



      /// The name the app registered with
  @JsonKey(
    
    name: r'client_name',
    required: true,
    includeIfNull: false,
  )


  final String clientName;



  @JsonKey(
    
    name: r'user_id',
    required: true,
    includeIfNull: false,
  )


  final String userId;



      /// Who connected it: their name, else their email
  @JsonKey(
    
    name: r'user_name',
    required: true,
    includeIfNull: false,
  )


  final String userName;



  @JsonKey(
    
    name: r'mine',
    required: true,
    includeIfNull: false,
  )


  final bool mine;



  @JsonKey(
    
    name: r'connected_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime connectedAt;



  @JsonKey(
    
    name: r'last_used_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? lastUsedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is McpConnection &&
      other.clientId == clientId &&
      other.clientName == clientName &&
      other.userId == userId &&
      other.userName == userName &&
      other.mine == mine &&
      other.connectedAt == connectedAt &&
      other.lastUsedAt == lastUsedAt;

    @override
    int get hashCode =>
        clientId.hashCode +
        clientName.hashCode +
        userId.hashCode +
        userName.hashCode +
        mine.hashCode +
        connectedAt.hashCode +
        (lastUsedAt == null ? 0 : lastUsedAt.hashCode);

  factory McpConnection.fromJson(Map<String, dynamic> json) => _$McpConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$McpConnectionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


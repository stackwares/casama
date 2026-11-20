//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'revoked_mcp_connection.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RevokedMcpConnection {
  /// Returns a new [RevokedMcpConnection] instance.
  RevokedMcpConnection({

    required  this.revoked,
  });

  @JsonKey(
    
    name: r'revoked',
    required: true,
    includeIfNull: false,
  )


  final String revoked;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RevokedMcpConnection &&
      other.revoked == revoked;

    @override
    int get hashCode =>
        revoked.hashCode;

  factory RevokedMcpConnection.fromJson(Map<String, dynamic> json) => _$RevokedMcpConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$RevokedMcpConnectionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


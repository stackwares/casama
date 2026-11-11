//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/integration.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'connect_flow_status.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConnectFlowStatus {
  /// Returns a new [ConnectFlowStatus] instance.
  ConnectFlowStatus({

    required  this.status,

     this.integration,

     this.error,
  });

  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final ConnectFlowStatusStatusEnum status;



  @JsonKey(
    
    name: r'integration',
    required: false,
    includeIfNull: false,
  )


  final Integration? integration;



  @JsonKey(
    
    name: r'error',
    required: false,
    includeIfNull: false,
  )


  final String? error;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ConnectFlowStatus &&
      other.status == status &&
      other.integration == integration &&
      other.error == error;

    @override
    int get hashCode =>
        status.hashCode +
        integration.hashCode +
        error.hashCode;

  factory ConnectFlowStatus.fromJson(Map<String, dynamic> json) => _$ConnectFlowStatusFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectFlowStatusToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ConnectFlowStatusStatusEnum {
@JsonValue(r'pending')
pending(r'pending'),
@JsonValue(r'connected')
connected(r'connected'),
@JsonValue(r'error')
error(r'error'),
@JsonValue(r'expired')
expired(r'expired');

const ConnectFlowStatusStatusEnum(this.value);

final String value;

@override
String toString() => value;
}



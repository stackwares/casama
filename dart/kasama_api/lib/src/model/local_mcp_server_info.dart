//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'local_mcp_server_info.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LocalMcpServerInfo {
  /// Returns a new [LocalMcpServerInfo] instance.
  LocalMcpServerInfo({

    required  this.key,

    required  this.label,

    required  this.kind,

    required  this.summary,

     this.timeoutS,
  });

  @JsonKey(
    
    name: r'key',
    required: true,
    includeIfNull: false,
  )


  final String key;



  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: false,
  )


  final String label;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final LocalMcpServerInfoKindEnum kind;



      /// Shown to the workspace, e.g. the command without its environment
  @JsonKey(
    
    name: r'summary',
    required: true,
    includeIfNull: false,
  )


  final String summary;



      /// Longest a call may take (default 1800 s); progress keeps it alive
          // minimum: 10
          // maximum: 7200
  @JsonKey(
    
    name: r'timeout_s',
    required: false,
    includeIfNull: false,
  )


  final int? timeoutS;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LocalMcpServerInfo &&
      other.key == key &&
      other.label == label &&
      other.kind == kind &&
      other.summary == summary &&
      other.timeoutS == timeoutS;

    @override
    int get hashCode =>
        key.hashCode +
        label.hashCode +
        kind.hashCode +
        summary.hashCode +
        timeoutS.hashCode;

  factory LocalMcpServerInfo.fromJson(Map<String, dynamic> json) => _$LocalMcpServerInfoFromJson(json);

  Map<String, dynamic> toJson() => _$LocalMcpServerInfoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum LocalMcpServerInfoKindEnum {
@JsonValue(r'stdio')
stdio(r'stdio'),
@JsonValue(r'loopback')
loopback(r'loopback');

const LocalMcpServerInfoKindEnum(this.value);

final String value;

@override
String toString() => value;
}



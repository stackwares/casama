//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dns_record_patch.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DnsRecordPatch {
  /// Returns a new [DnsRecordPatch] instance.
  DnsRecordPatch({

     this.host,

     this.type,

     this.answer,

     this.ttl = 300,

     this.priority,
  });

  @JsonKey(
    
    name: r'host',
    required: false,
    includeIfNull: false,
  )


  final String? host;



  @JsonKey(
    
    name: r'type',
    required: false,
    includeIfNull: false,
  )


  final String? type;



  @JsonKey(
    
    name: r'answer',
    required: false,
    includeIfNull: false,
  )


  final String? answer;



          // minimum: 300
          // maximum: 86400
  @JsonKey(
    defaultValue: 300,
    name: r'ttl',
    required: false,
    includeIfNull: false,
  )


  final int? ttl;



          // minimum: 0
          // maximum: 65535
  @JsonKey(
    
    name: r'priority',
    required: false,
    includeIfNull: false,
  )


  final int? priority;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DnsRecordPatch &&
      other.host == host &&
      other.type == type &&
      other.answer == answer &&
      other.ttl == ttl &&
      other.priority == priority;

    @override
    int get hashCode =>
        host.hashCode +
        type.hashCode +
        answer.hashCode +
        ttl.hashCode +
        (priority == null ? 0 : priority.hashCode);

  factory DnsRecordPatch.fromJson(Map<String, dynamic> json) => _$DnsRecordPatchFromJson(json);

  Map<String, dynamic> toJson() => _$DnsRecordPatchToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


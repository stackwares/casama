//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dns_record_item.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DnsRecordItem {
  /// Returns a new [DnsRecordItem] instance.
  DnsRecordItem({

    required  this.id,

    required  this.host,

    required  this.type,

    required  this.answer,

    required  this.ttl,

    required  this.priority,

    required  this.managed,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'host',
    required: true,
    includeIfNull: false,
  )


  final String host;



  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final String type;



  @JsonKey(
    
    name: r'answer',
    required: true,
    includeIfNull: false,
  )


  final String answer;



  @JsonKey(
    
    name: r'ttl',
    required: true,
    includeIfNull: false,
  )


  final int ttl;



  @JsonKey(
    
    name: r'priority',
    required: true,
    includeIfNull: true,
  )


  final int? priority;



  @JsonKey(
    
    name: r'managed',
    required: true,
    includeIfNull: false,
  )


  final bool managed;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DnsRecordItem &&
      other.id == id &&
      other.host == host &&
      other.type == type &&
      other.answer == answer &&
      other.ttl == ttl &&
      other.priority == priority &&
      other.managed == managed;

    @override
    int get hashCode =>
        id.hashCode +
        host.hashCode +
        type.hashCode +
        answer.hashCode +
        ttl.hashCode +
        (priority == null ? 0 : priority.hashCode) +
        managed.hashCode;

  factory DnsRecordItem.fromJson(Map<String, dynamic> json) => _$DnsRecordItemFromJson(json);

  Map<String, dynamic> toJson() => _$DnsRecordItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


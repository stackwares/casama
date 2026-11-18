//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'domain_record.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DomainRecord {
  /// Returns a new [DomainRecord] instance.
  DomainRecord({

    required  this.host,

    required  this.type,

    required  this.name,

    required  this.value,

    required  this.purpose,

    required  this.required_,

    required  this.seen,

    required  this.ok,
  });

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
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'value',
    required: true,
    includeIfNull: false,
  )


  final String value;



  @JsonKey(
    
    name: r'purpose',
    required: true,
    includeIfNull: false,
  )


  final String purpose;



  @JsonKey(
    
    name: r'required',
    required: true,
    includeIfNull: false,
  )


  final bool required_;



  @JsonKey(
    
    name: r'seen',
    required: true,
    includeIfNull: true,
  )


  final List<String>? seen;



  @JsonKey(
    
    name: r'ok',
    required: true,
    includeIfNull: true,
  )


  final bool? ok;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DomainRecord &&
      other.host == host &&
      other.type == type &&
      other.name == name &&
      other.value == value &&
      other.purpose == purpose &&
      other.required_ == required_ &&
      other.seen == seen &&
      other.ok == ok;

    @override
    int get hashCode =>
        host.hashCode +
        type.hashCode +
        name.hashCode +
        value.hashCode +
        purpose.hashCode +
        required_.hashCode +
        (seen == null ? 0 : seen.hashCode) +
        (ok == null ? 0 : ok.hashCode);

  factory DomainRecord.fromJson(Map<String, dynamic> json) => _$DomainRecordFromJson(json);

  Map<String, dynamic> toJson() => _$DomainRecordToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'vendor_reading.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VendorReading {
  /// Returns a new [VendorReading] instance.
  VendorReading({

    required  this.checkedAt,

    required  this.used,

    required  this.remaining,

    required  this.limitValue,

    required  this.resetsAt,

    required  this.status,

    required  this.source_,

    required  this.error,
  });

  @JsonKey(
    
    name: r'checked_at',
    required: true,
    includeIfNull: false,
  )


  final String checkedAt;



  @JsonKey(
    
    name: r'used',
    required: true,
    includeIfNull: true,
  )


  final num? used;



  @JsonKey(
    
    name: r'remaining',
    required: true,
    includeIfNull: true,
  )


  final num? remaining;



  @JsonKey(
    
    name: r'limit_value',
    required: true,
    includeIfNull: true,
  )


  final num? limitValue;



  @JsonKey(
    
    name: r'resets_at',
    required: true,
    includeIfNull: true,
  )


  final String? resetsAt;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final VendorReadingStatusEnum status;



  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final VendorReadingSource_Enum source_;



  @JsonKey(
    
    name: r'error',
    required: true,
    includeIfNull: true,
  )


  final String? error;





    @override
    bool operator ==(Object other) => identical(this, other) || other is VendorReading &&
      other.checkedAt == checkedAt &&
      other.used == used &&
      other.remaining == remaining &&
      other.limitValue == limitValue &&
      other.resetsAt == resetsAt &&
      other.status == status &&
      other.source_ == source_ &&
      other.error == error;

    @override
    int get hashCode =>
        checkedAt.hashCode +
        (used == null ? 0 : used.hashCode) +
        (remaining == null ? 0 : remaining.hashCode) +
        (limitValue == null ? 0 : limitValue.hashCode) +
        (resetsAt == null ? 0 : resetsAt.hashCode) +
        status.hashCode +
        source_.hashCode +
        (error == null ? 0 : error.hashCode);

  factory VendorReading.fromJson(Map<String, dynamic> json) => _$VendorReadingFromJson(json);

  Map<String, dynamic> toJson() => _$VendorReadingToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum VendorReadingStatusEnum {
@JsonValue(r'ok')
ok(r'ok'),
@JsonValue(r'low')
low(r'low'),
@JsonValue(r'out')
out_(r'out'),
@JsonValue(r'unknown')
unknown(r'unknown');

const VendorReadingStatusEnum(this.value);

final String value;

@override
String toString() => value;
}



enum VendorReadingSource_Enum {
@JsonValue(r'api')
api(r'api'),
@JsonValue(r'own_count')
ownCount(r'own_count'),
@JsonValue(r'manual')
manual(r'manual');

const VendorReadingSource_Enum(this.value);

final String value;

@override
String toString() => value;
}



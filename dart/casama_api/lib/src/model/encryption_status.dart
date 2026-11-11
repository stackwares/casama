//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'encryption_status.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EncryptionStatus {
  /// Returns a new [EncryptionStatus] instance.
  EncryptionStatus({

    required  this.mode,

    required  this.available,

    required  this.key,

    required  this.since,

    required  this.rotatedAt,
  });

  @JsonKey(
    
    name: r'mode',
    required: true,
    includeIfNull: false,
  )


  final EncryptionStatusModeEnum mode;



  @JsonKey(
    
    name: r'available',
    required: true,
    includeIfNull: false,
  )


  final bool available;



  @JsonKey(
    
    name: r'key',
    required: true,
    includeIfNull: true,
  )


  final EncryptionStatusKeyEnum? key;



  @JsonKey(
    
    name: r'since',
    required: true,
    includeIfNull: true,
  )


  final DateTime? since;



  @JsonKey(
    
    name: r'rotated_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? rotatedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is EncryptionStatus &&
      other.mode == mode &&
      other.available == available &&
      other.key == key &&
      other.since == since &&
      other.rotatedAt == rotatedAt;

    @override
    int get hashCode =>
        mode.hashCode +
        available.hashCode +
        (key == null ? 0 : key.hashCode) +
        (since == null ? 0 : since.hashCode) +
        (rotatedAt == null ? 0 : rotatedAt.hashCode);

  factory EncryptionStatus.fromJson(Map<String, dynamic> json) => _$EncryptionStatusFromJson(json);

  Map<String, dynamic> toJson() => _$EncryptionStatusToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum EncryptionStatusModeEnum {
@JsonValue(r'off')
off(r'off'),
@JsonValue(r'encrypting')
encrypting(r'encrypting'),
@JsonValue(r'on')
on_(r'on'),
@JsonValue(r'decrypting')
decrypting(r'decrypting');

const EncryptionStatusModeEnum(this.value);

final String value;

@override
String toString() => value;
}



enum EncryptionStatusKeyEnum {
@JsonValue(r'server_key')
serverKey(r'server_key'),
@JsonValue(r'aws_kms')
awsKms(r'aws_kms');

const EncryptionStatusKeyEnum(this.value);

final String value;

@override
String toString() => value;
}



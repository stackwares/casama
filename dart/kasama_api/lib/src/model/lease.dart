//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lease.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Lease {
  /// Returns a new [Lease] instance.
  Lease({

    required  this.computerId,

    required  this.holderType,

    required  this.holderId,

    required  this.mode,

    required  this.expiresAt,

    required  this.you,
  });

  @JsonKey(
    
    name: r'computer_id',
    required: true,
    includeIfNull: false,
  )


  final String computerId;



  @JsonKey(
    
    name: r'holder_type',
    required: true,
    includeIfNull: false,
  )


  final LeaseHolderTypeEnum holderType;



  @JsonKey(
    
    name: r'holder_id',
    required: true,
    includeIfNull: true,
  )


  final String? holderId;



  @JsonKey(
    
    name: r'mode',
    required: true,
    includeIfNull: false,
  )


  final LeaseModeEnum mode;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? expiresAt;



      /// Whether you hold it
  @JsonKey(
    
    name: r'you',
    required: true,
    includeIfNull: false,
  )


  final bool you;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Lease &&
      other.computerId == computerId &&
      other.holderType == holderType &&
      other.holderId == holderId &&
      other.mode == mode &&
      other.expiresAt == expiresAt &&
      other.you == you;

    @override
    int get hashCode =>
        computerId.hashCode +
        holderType.hashCode +
        (holderId == null ? 0 : holderId.hashCode) +
        mode.hashCode +
        (expiresAt == null ? 0 : expiresAt.hashCode) +
        you.hashCode;

  factory Lease.fromJson(Map<String, dynamic> json) => _$LeaseFromJson(json);

  Map<String, dynamic> toJson() => _$LeaseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum LeaseHolderTypeEnum {
@JsonValue(r'bot')
bot(r'bot'),
@JsonValue(r'user')
user(r'user');

const LeaseHolderTypeEnum(this.value);

final String value;

@override
String toString() => value;
}



enum LeaseModeEnum {
@JsonValue(r'view')
view(r'view'),
@JsonValue(r'control')
control(r'control');

const LeaseModeEnum(this.value);

final String value;

@override
String toString() => value;
}



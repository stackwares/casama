//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_code.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchCode {
  /// Returns a new [WatchCode] instance.
  WatchCode({

    required  this.code,

    required  this.expiresAt,

    required  this.pollEveryS,
  });

  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;



          // minimum: 1
  @JsonKey(
    
    name: r'poll_every_s',
    required: true,
    includeIfNull: false,
  )


  final int pollEveryS;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchCode &&
      other.code == code &&
      other.expiresAt == expiresAt &&
      other.pollEveryS == pollEveryS;

    @override
    int get hashCode =>
        code.hashCode +
        expiresAt.hashCode +
        pollEveryS.hashCode;

  factory WatchCode.fromJson(Map<String, dynamic> json) => _$WatchCodeFromJson(json);

  Map<String, dynamic> toJson() => _$WatchCodeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


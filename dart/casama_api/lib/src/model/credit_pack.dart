//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'credit_pack.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreditPack {
  /// Returns a new [CreditPack] instance.
  CreditPack({

    required  this.code,

    required  this.name,

    required  this.creditsUsd,

    required  this.web,
  });

  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'credits_usd',
    required: true,
    includeIfNull: false,
  )


  final num creditsUsd;



  @JsonKey(
    
    name: r'web',
    required: true,
    includeIfNull: false,
  )


  final bool web;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreditPack &&
      other.code == code &&
      other.name == name &&
      other.creditsUsd == creditsUsd &&
      other.web == web;

    @override
    int get hashCode =>
        code.hashCode +
        name.hashCode +
        creditsUsd.hashCode +
        web.hashCode;

  factory CreditPack.fromJson(Map<String, dynamic> json) => _$CreditPackFromJson(json);

  Map<String, dynamic> toJson() => _$CreditPackToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


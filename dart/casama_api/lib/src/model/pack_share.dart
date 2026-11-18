//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/pack_secret_finding.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_share.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackShare {
  /// Returns a new [PackShare] instance.
  PackShare({

    required  this.id,

    required  this.url,

    required  this.token,

    required  this.expiresAt,

    required  this.findings,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;



  @JsonKey(
    
    name: r'token',
    required: true,
    includeIfNull: false,
  )


  final String token;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;



  @JsonKey(
    
    name: r'findings',
    required: true,
    includeIfNull: false,
  )


  final List<PackSecretFinding> findings;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackShare &&
      other.id == id &&
      other.url == url &&
      other.token == token &&
      other.expiresAt == expiresAt &&
      other.findings == findings;

    @override
    int get hashCode =>
        id.hashCode +
        url.hashCode +
        token.hashCode +
        expiresAt.hashCode +
        findings.hashCode;

  factory PackShare.fromJson(Map<String, dynamic> json) => _$PackShareFromJson(json);

  Map<String, dynamic> toJson() => _$PackShareToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


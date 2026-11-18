//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sign_in_code.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SignInCode {
  /// Returns a new [SignInCode] instance.
  SignInCode({

    required  this.code,

    required  this.expiresAt,

    required  this.serverUrl,

    required  this.reachable,

    required  this.pairUrl,
  });

      /// Shown once, inside the QR code; valid a few minutes
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



      /// The address a phone uses for this server
  @JsonKey(
    
    name: r'server_url',
    required: true,
    includeIfNull: false,
  )


  final String serverUrl;



      /// false when that address only works on this machine or network; a phone elsewhere needs remote access turned on first
  @JsonKey(
    
    name: r'reachable',
    required: true,
    includeIfNull: false,
  )


  final bool reachable;



      /// What the QR code holds: a link that opens the app with the code
  @JsonKey(
    
    name: r'pair_url',
    required: true,
    includeIfNull: false,
  )


  final String pairUrl;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SignInCode &&
      other.code == code &&
      other.expiresAt == expiresAt &&
      other.serverUrl == serverUrl &&
      other.reachable == reachable &&
      other.pairUrl == pairUrl;

    @override
    int get hashCode =>
        code.hashCode +
        expiresAt.hashCode +
        serverUrl.hashCode +
        reachable.hashCode +
        pairUrl.hashCode;

  factory SignInCode.fromJson(Map<String, dynamic> json) => _$SignInCodeFromJson(json);

  Map<String, dynamic> toJson() => _$SignInCodeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


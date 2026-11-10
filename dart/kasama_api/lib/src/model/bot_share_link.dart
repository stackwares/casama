//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_share_link.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotShareLink {
  /// Returns a new [BotShareLink] instance.
  BotShareLink({

    required  this.token,

    required  this.url,

    required  this.expiresAt,
  });

  @JsonKey(
    
    name: r'token',
    required: true,
    includeIfNull: false,
  )


  final String token;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? expiresAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotShareLink &&
      other.token == token &&
      other.url == url &&
      other.expiresAt == expiresAt;

    @override
    int get hashCode =>
        token.hashCode +
        url.hashCode +
        (expiresAt == null ? 0 : expiresAt.hashCode);

  factory BotShareLink.fromJson(Map<String, dynamic> json) => _$BotShareLinkFromJson(json);

  Map<String, dynamic> toJson() => _$BotShareLinkToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


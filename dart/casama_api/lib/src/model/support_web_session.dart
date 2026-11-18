//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'support_web_session.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SupportWebSession {
  /// Returns a new [SupportWebSession] instance.
  SupportWebSession({

    required  this.session,

    required  this.expiresAt,
  });

  @JsonKey(
    
    name: r'session',
    required: true,
    includeIfNull: false,
  )


  final String session;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SupportWebSession &&
      other.session == session &&
      other.expiresAt == expiresAt;

    @override
    int get hashCode =>
        session.hashCode +
        expiresAt.hashCode;

  factory SupportWebSession.fromJson(Map<String, dynamic> json) => _$SupportWebSessionFromJson(json);

  Map<String, dynamic> toJson() => _$SupportWebSessionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


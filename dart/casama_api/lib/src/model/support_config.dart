//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'support_config.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SupportConfig {
  /// Returns a new [SupportConfig] instance.
  SupportConfig({

    required  this.assistant,

    required  this.tickets,

    required  this.email,

    required  this.docsUrl,
  });

  @JsonKey(
    
    name: r'assistant',
    required: true,
    includeIfNull: false,
  )


  final bool assistant;



  @JsonKey(
    
    name: r'tickets',
    required: true,
    includeIfNull: false,
  )


  final bool tickets;



  @JsonKey(
    
    name: r'email',
    required: true,
    includeIfNull: false,
  )


  final String email;



  @JsonKey(
    
    name: r'docs_url',
    required: true,
    includeIfNull: false,
  )


  final String docsUrl;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SupportConfig &&
      other.assistant == assistant &&
      other.tickets == tickets &&
      other.email == email &&
      other.docsUrl == docsUrl;

    @override
    int get hashCode =>
        assistant.hashCode +
        tickets.hashCode +
        email.hashCode +
        docsUrl.hashCode;

  factory SupportConfig.fromJson(Map<String, dynamic> json) => _$SupportConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SupportConfigToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


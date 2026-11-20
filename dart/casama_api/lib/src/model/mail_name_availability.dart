//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mail_name_availability.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MailNameAvailability {
  /// Returns a new [MailNameAvailability] instance.
  MailNameAvailability({

    required  this.name,

    required  this.available,

    required  this.issue,

    required  this.suggestions,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'available',
    required: true,
    includeIfNull: false,
  )


  final bool available;



  @JsonKey(
    
    name: r'issue',
    required: true,
    includeIfNull: true,
  )


  final String? issue;



  @JsonKey(
    
    name: r'suggestions',
    required: true,
    includeIfNull: false,
  )


  final List<String> suggestions;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MailNameAvailability &&
      other.name == name &&
      other.available == available &&
      other.issue == issue &&
      other.suggestions == suggestions;

    @override
    int get hashCode =>
        name.hashCode +
        available.hashCode +
        (issue == null ? 0 : issue.hashCode) +
        suggestions.hashCode;

  factory MailNameAvailability.fromJson(Map<String, dynamic> json) => _$MailNameAvailabilityFromJson(json);

  Map<String, dynamic> toJson() => _$MailNameAvailabilityToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


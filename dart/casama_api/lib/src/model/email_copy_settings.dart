//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'email_copy_settings.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EmailCopySettings {
  /// Returns a new [EmailCopySettings] instance.
  EmailCopySettings({

    required  this.copy,

    required  this.defaults,
  });

      /// The owner's words by email kind; a missing field uses the text in code
  @JsonKey(
    
    name: r'copy',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> copy;



      /// The text in code for each editable email, to start from
  @JsonKey(
    
    name: r'defaults',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> defaults;





    @override
    bool operator ==(Object other) => identical(this, other) || other is EmailCopySettings &&
      other.copy == copy &&
      other.defaults == defaults;

    @override
    int get hashCode =>
        copy.hashCode +
        defaults.hashCode;

  factory EmailCopySettings.fromJson(Map<String, dynamic> json) => _$EmailCopySettingsFromJson(json);

  Map<String, dynamic> toJson() => _$EmailCopySettingsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


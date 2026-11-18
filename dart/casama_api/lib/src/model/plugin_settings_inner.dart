//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plugin_settings_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PluginSettingsInner {
  /// Returns a new [PluginSettingsInner] instance.
  PluginSettingsInner({

    required  this.name,

    required  this.label,

    required  this.description,

    required  this.server,

    required  this.default_,

    required  this.value,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: false,
  )


  final String label;



  @JsonKey(
    
    name: r'description',
    required: true,
    includeIfNull: false,
  )


  final String description;



  @JsonKey(
    
    name: r'server',
    required: true,
    includeIfNull: false,
  )


  final String server;



  @JsonKey(
    
    name: r'default',
    required: true,
    includeIfNull: true,
  )


  final String? default_;



  @JsonKey(
    
    name: r'value',
    required: true,
    includeIfNull: false,
  )


  final String value;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PluginSettingsInner &&
      other.name == name &&
      other.label == label &&
      other.description == description &&
      other.server == server &&
      other.default_ == default_ &&
      other.value == value;

    @override
    int get hashCode =>
        name.hashCode +
        label.hashCode +
        description.hashCode +
        server.hashCode +
        (default_ == null ? 0 : default_.hashCode) +
        value.hashCode;

  factory PluginSettingsInner.fromJson(Map<String, dynamic> json) => _$PluginSettingsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$PluginSettingsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


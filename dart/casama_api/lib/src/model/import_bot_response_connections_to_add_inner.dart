//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'import_bot_response_connections_to_add_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ImportBotResponseConnectionsToAddInner {
  /// Returns a new [ImportBotResponseConnectionsToAddInner] instance.
  ImportBotResponseConnectionsToAddInner({

    required  this.kind,

    required  this.name,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final String kind;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ImportBotResponseConnectionsToAddInner &&
      other.kind == kind &&
      other.name == name;

    @override
    int get hashCode =>
        kind.hashCode +
        name.hashCode;

  factory ImportBotResponseConnectionsToAddInner.fromJson(Map<String, dynamic> json) => _$ImportBotResponseConnectionsToAddInnerFromJson(json);

  Map<String, dynamic> toJson() => _$ImportBotResponseConnectionsToAddInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


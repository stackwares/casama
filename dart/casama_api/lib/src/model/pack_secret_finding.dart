//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_secret_finding.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackSecretFinding {
  /// Returns a new [PackSecretFinding] instance.
  PackSecretFinding({

    required  this.path,

    required  this.line,

    required  this.what,
  });

  @JsonKey(
    
    name: r'path',
    required: true,
    includeIfNull: false,
  )


  final String path;



  @JsonKey(
    
    name: r'line',
    required: true,
    includeIfNull: false,
  )


  final int line;



  @JsonKey(
    
    name: r'what',
    required: true,
    includeIfNull: false,
  )


  final String what;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackSecretFinding &&
      other.path == path &&
      other.line == line &&
      other.what == what;

    @override
    int get hashCode =>
        path.hashCode +
        line.hashCode +
        what.hashCode;

  factory PackSecretFinding.fromJson(Map<String, dynamic> json) => _$PackSecretFindingFromJson(json);

  Map<String, dynamic> toJson() => _$PackSecretFindingToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


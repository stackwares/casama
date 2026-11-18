//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/pack_export_file.dart';
import 'package:casama_api/src/model/pack_secret_finding.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_export.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackExport {
  /// Returns a new [PackExport] instance.
  PackExport({

    required  this.name,

    required  this.files,

    required  this.findings,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'files',
    required: true,
    includeIfNull: false,
  )


  final List<PackExportFile> files;



      /// Lines that look like keys: fix them before sharing
  @JsonKey(
    
    name: r'findings',
    required: true,
    includeIfNull: false,
  )


  final List<PackSecretFinding> findings;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackExport &&
      other.name == name &&
      other.files == files &&
      other.findings == findings;

    @override
    int get hashCode =>
        name.hashCode +
        files.hashCode +
        findings.hashCode;

  factory PackExport.fromJson(Map<String, dynamic> json) => _$PackExportFromJson(json);

  Map<String, dynamic> toJson() => _$PackExportToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


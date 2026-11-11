//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'workspace_files_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WorkspaceFilesResult {
  /// Returns a new [WorkspaceFilesResult] instance.
  WorkspaceFilesResult({

    required  this.created,

    required  this.updated,

    required  this.deleted,

    required  this.unchanged,

    required  this.errors,

    required  this.dryRun,
  });

  @JsonKey(
    
    name: r'created',
    required: true,
    includeIfNull: false,
  )


  final List<String> created;



  @JsonKey(
    
    name: r'updated',
    required: true,
    includeIfNull: false,
  )


  final List<String> updated;



  @JsonKey(
    
    name: r'deleted',
    required: true,
    includeIfNull: false,
  )


  final List<String> deleted;



  @JsonKey(
    
    name: r'unchanged',
    required: true,
    includeIfNull: false,
  )


  final int unchanged;



  @JsonKey(
    
    name: r'errors',
    required: true,
    includeIfNull: false,
  )


  final List<String> errors;



  @JsonKey(
    
    name: r'dry_run',
    required: true,
    includeIfNull: false,
  )


  final bool dryRun;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WorkspaceFilesResult &&
      other.created == created &&
      other.updated == updated &&
      other.deleted == deleted &&
      other.unchanged == unchanged &&
      other.errors == errors &&
      other.dryRun == dryRun;

    @override
    int get hashCode =>
        created.hashCode +
        updated.hashCode +
        deleted.hashCode +
        unchanged.hashCode +
        errors.hashCode +
        dryRun.hashCode;

  factory WorkspaceFilesResult.fromJson(Map<String, dynamic> json) => _$WorkspaceFilesResultFromJson(json);

  Map<String, dynamic> toJson() => _$WorkspaceFilesResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


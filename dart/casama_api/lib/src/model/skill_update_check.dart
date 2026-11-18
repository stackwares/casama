//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'skill_update_check.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SkillUpdateCheck {
  /// Returns a new [SkillUpdateCheck] instance.
  SkillUpdateCheck({

    required  this.currentCommit,

    required  this.latestCommit,

    required  this.hasUpdate,

    required  this.diff,

    required  this.filesAdded,

    required  this.filesRemoved,

    required  this.filesChanged,
  });

  @JsonKey(
    
    name: r'current_commit',
    required: true,
    includeIfNull: false,
  )


  final String currentCommit;



  @JsonKey(
    
    name: r'latest_commit',
    required: true,
    includeIfNull: false,
  )


  final String latestCommit;



  @JsonKey(
    
    name: r'has_update',
    required: true,
    includeIfNull: false,
  )


  final bool hasUpdate;



      /// SKILL.md line diff (+, -, space)
  @JsonKey(
    
    name: r'diff',
    required: true,
    includeIfNull: false,
  )


  final List<String> diff;



  @JsonKey(
    
    name: r'files_added',
    required: true,
    includeIfNull: false,
  )


  final List<String> filesAdded;



  @JsonKey(
    
    name: r'files_removed',
    required: true,
    includeIfNull: false,
  )


  final List<String> filesRemoved;



  @JsonKey(
    
    name: r'files_changed',
    required: true,
    includeIfNull: false,
  )


  final List<String> filesChanged;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SkillUpdateCheck &&
      other.currentCommit == currentCommit &&
      other.latestCommit == latestCommit &&
      other.hasUpdate == hasUpdate &&
      other.diff == diff &&
      other.filesAdded == filesAdded &&
      other.filesRemoved == filesRemoved &&
      other.filesChanged == filesChanged;

    @override
    int get hashCode =>
        currentCommit.hashCode +
        latestCommit.hashCode +
        hasUpdate.hashCode +
        diff.hashCode +
        filesAdded.hashCode +
        filesRemoved.hashCode +
        filesChanged.hashCode;

  factory SkillUpdateCheck.fromJson(Map<String, dynamic> json) => _$SkillUpdateCheckFromJson(json);

  Map<String, dynamic> toJson() => _$SkillUpdateCheckToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


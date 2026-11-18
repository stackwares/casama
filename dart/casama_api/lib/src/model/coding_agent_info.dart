//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'coding_agent_info.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CodingAgentInfo {
  /// Returns a new [CodingAgentInfo] instance.
  CodingAgentInfo({

    required  this.id,

    required  this.label,

    required  this.bin,

    required  this.where,

    required  this.needsFolder,

    required  this.hint,

    required  this.preallowed,
  });

      /// What coding.delegate takes as `agent`
  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: false,
  )


  final String label;



      /// The command the desktop app looks for
  @JsonKey(
    
    name: r'bin',
    required: true,
    includeIfNull: false,
  )


  final String bin;



      /// my_computer and/or bot_computer
  @JsonKey(
    
    name: r'where',
    required: true,
    includeIfNull: false,
  )


  final List<String> where;



  @JsonKey(
    
    name: r'needs_folder',
    required: true,
    includeIfNull: false,
  )


  final bool needsFolder;



  @JsonKey(
    
    name: r'hint',
    required: true,
    includeIfNull: true,
  )


  final String? hint;



      /// Runs whenever commands are on; any other agent needs one Allow on each computer (allowed_coding_agents)
  @JsonKey(
    
    name: r'preallowed',
    required: true,
    includeIfNull: false,
  )


  final bool preallowed;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CodingAgentInfo &&
      other.id == id &&
      other.label == label &&
      other.bin == bin &&
      other.where == where &&
      other.needsFolder == needsFolder &&
      other.hint == hint &&
      other.preallowed == preallowed;

    @override
    int get hashCode =>
        id.hashCode +
        label.hashCode +
        bin.hashCode +
        where.hashCode +
        needsFolder.hashCode +
        (hint == null ? 0 : hint.hashCode) +
        preallowed.hashCode;

  factory CodingAgentInfo.fromJson(Map<String, dynamic> json) => _$CodingAgentInfoFromJson(json);

  Map<String, dynamic> toJson() => _$CodingAgentInfoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


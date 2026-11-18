//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'for_you_approval.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ForYouApproval {
  /// Returns a new [ForYouApproval] instance.
  ForYouApproval({

    required  this.id,

    required  this.botId,

    required  this.summary,

    required  this.risk,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'summary',
    required: true,
    includeIfNull: false,
  )


  final String summary;



  @JsonKey(
    
    name: r'risk',
    required: true,
    includeIfNull: false,
  )


  final String risk;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ForYouApproval &&
      other.id == id &&
      other.botId == botId &&
      other.summary == summary &&
      other.risk == risk &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        summary.hashCode +
        risk.hashCode +
        createdAt.hashCode;

  factory ForYouApproval.fromJson(Map<String, dynamic> json) => _$ForYouApprovalFromJson(json);

  Map<String, dynamic> toJson() => _$ForYouApprovalToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


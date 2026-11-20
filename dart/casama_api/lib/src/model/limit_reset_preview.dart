//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'limit_reset_preview.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LimitResetPreview {
  /// Returns a new [LimitResetPreview] instance.
  LimitResetPreview({

    required  this.workspaces,

    required  this.byPlan,

    required  this.creditsUsd,

    required  this.costUsd,
  });

          // minimum: 0
  @JsonKey(
    
    name: r'workspaces',
    required: true,
    includeIfNull: false,
  )


  final int workspaces;



  @JsonKey(
    
    name: r'by_plan',
    required: true,
    includeIfNull: false,
  )


  final Map<String, int> byPlan;



          // minimum: 0
  @JsonKey(
    
    name: r'credits_usd',
    required: true,
    includeIfNull: false,
  )


  final num creditsUsd;



          // minimum: 0
  @JsonKey(
    
    name: r'cost_usd',
    required: true,
    includeIfNull: false,
  )


  final num costUsd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LimitResetPreview &&
      other.workspaces == workspaces &&
      other.byPlan == byPlan &&
      other.creditsUsd == creditsUsd &&
      other.costUsd == costUsd;

    @override
    int get hashCode =>
        workspaces.hashCode +
        byPlan.hashCode +
        creditsUsd.hashCode +
        costUsd.hashCode;

  factory LimitResetPreview.fromJson(Map<String, dynamic> json) => _$LimitResetPreviewFromJson(json);

  Map<String, dynamic> toJson() => _$LimitResetPreviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


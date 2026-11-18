//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'support_web_stats_gaps_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SupportWebStatsGapsInner {
  /// Returns a new [SupportWebStatsGapsInner] instance.
  SupportWebStatsGapsInner({

    required  this.question,

    required  this.page,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'question',
    required: true,
    includeIfNull: false,
  )


  final String question;



  @JsonKey(
    
    name: r'page',
    required: true,
    includeIfNull: true,
  )


  final String? page;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SupportWebStatsGapsInner &&
      other.question == question &&
      other.page == page &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        question.hashCode +
        (page == null ? 0 : page.hashCode) +
        createdAt.hashCode;

  factory SupportWebStatsGapsInner.fromJson(Map<String, dynamic> json) => _$SupportWebStatsGapsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$SupportWebStatsGapsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'comp_code_preview.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CompCodePreview {
  /// Returns a new [CompCodePreview] instance.
  CompCodePreview({

    required  this.planCode,

    required  this.planName,

    required  this.months,
  });

  @JsonKey(
    
    name: r'plan_code',
    required: true,
    includeIfNull: false,
  )


  final String planCode;



  @JsonKey(
    
    name: r'plan_name',
    required: true,
    includeIfNull: false,
  )


  final String planName;



  @JsonKey(
    
    name: r'months',
    required: true,
    includeIfNull: false,
  )


  final int months;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CompCodePreview &&
      other.planCode == planCode &&
      other.planName == planName &&
      other.months == months;

    @override
    int get hashCode =>
        planCode.hashCode +
        planName.hashCode +
        months.hashCode;

  factory CompCodePreview.fromJson(Map<String, dynamic> json) => _$CompCodePreviewFromJson(json);

  Map<String, dynamic> toJson() => _$CompCodePreviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'waitlist_batch.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WaitlistBatch {
  /// Returns a new [WaitlistBatch] instance.
  WaitlistBatch({

    required  this.day,

    required  this.ranAt,

    required  this.admitted,

    required  this.skippedReason,

    required  this.detail,
  });

  @JsonKey(
    
    name: r'day',
    required: true,
    includeIfNull: false,
  )


  final String day;



  @JsonKey(
    
    name: r'ran_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime ranAt;



  @JsonKey(
    
    name: r'admitted',
    required: true,
    includeIfNull: false,
  )


  final int admitted;



  @JsonKey(
    
    name: r'skipped_reason',
    required: true,
    includeIfNull: true,
  )


  final String? skippedReason;



  @JsonKey(
    
    name: r'detail',
    required: true,
    includeIfNull: true,
  )


  final String? detail;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WaitlistBatch &&
      other.day == day &&
      other.ranAt == ranAt &&
      other.admitted == admitted &&
      other.skippedReason == skippedReason &&
      other.detail == detail;

    @override
    int get hashCode =>
        day.hashCode +
        ranAt.hashCode +
        admitted.hashCode +
        (skippedReason == null ? 0 : skippedReason.hashCode) +
        (detail == null ? 0 : detail.hashCode);

  factory WaitlistBatch.fromJson(Map<String, dynamic> json) => _$WaitlistBatchFromJson(json);

  Map<String, dynamic> toJson() => _$WaitlistBatchToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


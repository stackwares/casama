//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'computer_usage_day.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComputerUsageDay {
  /// Returns a new [ComputerUsageDay] instance.
  ComputerUsageDay({

    required  this.date,

    required  this.seconds,
  });

  @JsonKey(
    
    name: r'date',
    required: true,
    includeIfNull: false,
  )


  final String date;



  @JsonKey(
    
    name: r'seconds',
    required: true,
    includeIfNull: false,
  )


  final int seconds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ComputerUsageDay &&
      other.date == date &&
      other.seconds == seconds;

    @override
    int get hashCode =>
        date.hashCode +
        seconds.hashCode;

  factory ComputerUsageDay.fromJson(Map<String, dynamic> json) => _$ComputerUsageDayFromJson(json);

  Map<String, dynamic> toJson() => _$ComputerUsageDayToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


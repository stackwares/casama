//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'computer_size.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComputerSize {
  /// Returns a new [ComputerSize] instance.
  ComputerSize({

     this.cpus,

     this.memoryMb,

     this.diskGb,
  });

  @JsonKey(
    
    name: r'cpus',
    required: false,
    includeIfNull: false,
  )


  final num? cpus;



  @JsonKey(
    
    name: r'memory_mb',
    required: false,
    includeIfNull: false,
  )


  final num? memoryMb;



  @JsonKey(
    
    name: r'disk_gb',
    required: false,
    includeIfNull: false,
  )


  final num? diskGb;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ComputerSize &&
      other.cpus == cpus &&
      other.memoryMb == memoryMb &&
      other.diskGb == diskGb;

    @override
    int get hashCode =>
        cpus.hashCode +
        memoryMb.hashCode +
        diskGb.hashCode;

  factory ComputerSize.fromJson(Map<String, dynamic> json) => _$ComputerSizeFromJson(json);

  Map<String, dynamic> toJson() => _$ComputerSizeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


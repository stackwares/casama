//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report_receipt.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportReceipt {
  /// Returns a new [ReportReceipt] instance.
  ReportReceipt({

    required  this.id,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReportReceipt &&
      other.id == id;

    @override
    int get hashCode =>
        id.hashCode;

  factory ReportReceipt.fromJson(Map<String, dynamic> json) => _$ReportReceiptFromJson(json);

  Map<String, dynamic> toJson() => _$ReportReceiptToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


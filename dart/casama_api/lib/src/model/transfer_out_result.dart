//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transfer_out_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TransferOutResult {
  /// Returns a new [TransferOutResult] instance.
  TransferOutResult({

    required  this.code,
  });

  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TransferOutResult &&
      other.code == code;

    @override
    int get hashCode =>
        code.hashCode;

  factory TransferOutResult.fromJson(Map<String, dynamic> json) => _$TransferOutResultFromJson(json);

  Map<String, dynamic> toJson() => _$TransferOutResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


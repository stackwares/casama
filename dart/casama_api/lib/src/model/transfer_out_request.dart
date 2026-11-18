//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transfer_out_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TransferOutRequest {
  /// Returns a new [TransferOutRequest] instance.
  TransferOutRequest({

    required  this.confirmName,
  });

  @JsonKey(
    
    name: r'confirm_name',
    required: true,
    includeIfNull: false,
  )


  final String confirmName;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TransferOutRequest &&
      other.confirmName == confirmName;

    @override
    int get hashCode =>
        confirmName.hashCode;

  factory TransferOutRequest.fromJson(Map<String, dynamic> json) => _$TransferOutRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TransferOutRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


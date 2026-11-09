//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'take_lease_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TakeLeaseRequest {
  /// Returns a new [TakeLeaseRequest] instance.
  TakeLeaseRequest({

     this.allowShell,
  });

      /// Let the bot keep using shell and file tools while you have control
  @JsonKey(
    
    name: r'allow_shell',
    required: false,
    includeIfNull: false,
  )


  final bool? allowShell;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TakeLeaseRequest &&
      other.allowShell == allowShell;

    @override
    int get hashCode =>
        allowShell.hashCode;

  factory TakeLeaseRequest.fromJson(Map<String, dynamic> json) => _$TakeLeaseRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TakeLeaseRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


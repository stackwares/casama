//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_comp_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateCompRequest {
  /// Returns a new [UpdateCompRequest] instance.
  UpdateCompRequest({

     this.extendMonths,

     this.revoke,
  });

          // minimum: 1
          // maximum: 36
  @JsonKey(
    
    name: r'extend_months',
    required: false,
    includeIfNull: false,
  )


  final int? extendMonths;



  @JsonKey(
    
    name: r'revoke',
    required: false,
    includeIfNull: false,
  )


  final bool? revoke;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateCompRequest &&
      other.extendMonths == extendMonths &&
      other.revoke == revoke;

    @override
    int get hashCode =>
        extendMonths.hashCode +
        revoke.hashCode;

  factory UpdateCompRequest.fromJson(Map<String, dynamic> json) => _$UpdateCompRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateCompRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


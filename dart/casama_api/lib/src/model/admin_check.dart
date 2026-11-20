//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_check.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminCheck {
  /// Returns a new [AdminCheck] instance.
  AdminCheck({

    required  this.verifiedAt,
  });

  @JsonKey(
    
    name: r'verified_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime verifiedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminCheck &&
      other.verifiedAt == verifiedAt;

    @override
    int get hashCode =>
        verifiedAt.hashCode;

  factory AdminCheck.fromJson(Map<String, dynamic> json) => _$AdminCheckFromJson(json);

  Map<String, dynamic> toJson() => _$AdminCheckToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


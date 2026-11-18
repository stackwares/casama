//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'accepted.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Accepted {
  /// Returns a new [Accepted] instance.
  Accepted({

    required  this.accepted,
  });

  @JsonKey(
    
    name: r'accepted',
    required: true,
    includeIfNull: false,
  )


  final bool accepted;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Accepted &&
      other.accepted == accepted;

    @override
    int get hashCode =>
        accepted.hashCode;

  factory Accepted.fromJson(Map<String, dynamic> json) => _$AcceptedFromJson(json);

  Map<String, dynamic> toJson() => _$AcceptedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


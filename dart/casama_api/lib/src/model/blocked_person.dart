//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'blocked_person.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BlockedPerson {
  /// Returns a new [BlockedPerson] instance.
  BlockedPerson({

    required  this.userId,

    required  this.name,

    required  this.blockedAt,
  });

  @JsonKey(
    
    name: r'user_id',
    required: true,
    includeIfNull: false,
  )


  final String userId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'blocked_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime blockedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BlockedPerson &&
      other.userId == userId &&
      other.name == name &&
      other.blockedAt == blockedAt;

    @override
    int get hashCode =>
        userId.hashCode +
        name.hashCode +
        blockedAt.hashCode;

  factory BlockedPerson.fromJson(Map<String, dynamic> json) => _$BlockedPersonFromJson(json);

  Map<String, dynamic> toJson() => _$BlockedPersonToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_self_person.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchSelfPerson {
  /// Returns a new [WatchSelfPerson] instance.
  WatchSelfPerson({

    required  this.name,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchSelfPerson &&
      other.name == name;

    @override
    int get hashCode =>
        name.hashCode;

  factory WatchSelfPerson.fromJson(Map<String, dynamic> json) => _$WatchSelfPersonFromJson(json);

  Map<String, dynamic> toJson() => _$WatchSelfPersonToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


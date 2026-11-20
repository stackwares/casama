//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_mail_reserved_names.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminMailReservedNames {
  /// Returns a new [AdminMailReservedNames] instance.
  AdminMailReservedNames({

    required  this.names,
  });

  @JsonKey(
    
    name: r'names',
    required: true,
    includeIfNull: false,
  )


  final List<String> names;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminMailReservedNames &&
      other.names == names;

    @override
    int get hashCode =>
        names.hashCode;

  factory AdminMailReservedNames.fromJson(Map<String, dynamic> json) => _$AdminMailReservedNamesFromJson(json);

  Map<String, dynamic> toJson() => _$AdminMailReservedNamesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'deleted_user_fact.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeletedUserFact {
  /// Returns a new [DeletedUserFact] instance.
  DeletedUserFact({

    required  this.deleted,
  });

  @JsonKey(
    
    name: r'deleted',
    required: true,
    includeIfNull: false,
  )


  final String deleted;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeletedUserFact &&
      other.deleted == deleted;

    @override
    int get hashCode =>
        deleted.hashCode;

  factory DeletedUserFact.fromJson(Map<String, dynamic> json) => _$DeletedUserFactFromJson(json);

  Map<String, dynamic> toJson() => _$DeletedUserFactToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


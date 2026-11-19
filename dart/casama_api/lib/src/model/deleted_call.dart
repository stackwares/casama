//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'deleted_call.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeletedCall {
  /// Returns a new [DeletedCall] instance.
  DeletedCall({

    required  this.deleted,
  });

  @JsonKey(
    
    name: r'deleted',
    required: true,
    includeIfNull: false,
  )


  final int deleted;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeletedCall &&
      other.deleted == deleted;

    @override
    int get hashCode =>
        deleted.hashCode;

  factory DeletedCall.fromJson(Map<String, dynamic> json) => _$DeletedCallFromJson(json);

  Map<String, dynamic> toJson() => _$DeletedCallToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


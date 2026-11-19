//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'deleted_watch_keys.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeletedWatchKeys {
  /// Returns a new [DeletedWatchKeys] instance.
  DeletedWatchKeys({

    required  this.deleted,
  });

          // minimum: 0
  @JsonKey(
    
    name: r'deleted',
    required: true,
    includeIfNull: false,
  )


  final int deleted;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeletedWatchKeys &&
      other.deleted == deleted;

    @override
    int get hashCode =>
        deleted.hashCode;

  factory DeletedWatchKeys.fromJson(Map<String, dynamic> json) => _$DeletedWatchKeysFromJson(json);

  Map<String, dynamic> toJson() => _$DeletedWatchKeysToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'deleted_watcher.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeletedWatcher {
  /// Returns a new [DeletedWatcher] instance.
  DeletedWatcher({

    required  this.deleted,
  });

  @JsonKey(
    
    name: r'deleted',
    required: true,
    includeIfNull: false,
  )


  final String deleted;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeletedWatcher &&
      other.deleted == deleted;

    @override
    int get hashCode =>
        deleted.hashCode;

  factory DeletedWatcher.fromJson(Map<String, dynamic> json) => _$DeletedWatcherFromJson(json);

  Map<String, dynamic> toJson() => _$DeletedWatcherToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'removed_link_server.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RemovedLinkServer {
  /// Returns a new [RemovedLinkServer] instance.
  RemovedLinkServer({

    required  this.removed,
  });

  @JsonKey(
    
    name: r'removed',
    required: true,
    includeIfNull: false,
  )


  final String removed;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RemovedLinkServer &&
      other.removed == removed;

    @override
    int get hashCode =>
        removed.hashCode;

  factory RemovedLinkServer.fromJson(Map<String, dynamic> json) => _$RemovedLinkServerFromJson(json);

  Map<String, dynamic> toJson() => _$RemovedLinkServerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


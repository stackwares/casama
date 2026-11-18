//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_handoff_sent.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchHandoffSent {
  /// Returns a new [WatchHandoffSent] instance.
  WatchHandoffSent({

    required  this.sent,
  });

  @JsonKey(
    
    name: r'sent',
    required: true,
    includeIfNull: false,
  )


  final int sent;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchHandoffSent &&
      other.sent == sent;

    @override
    int get hashCode =>
        sent.hashCode;

  factory WatchHandoffSent.fromJson(Map<String, dynamic> json) => _$WatchHandoffSentFromJson(json);

  Map<String, dynamic> toJson() => _$WatchHandoffSentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_signed_out.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchSignedOut {
  /// Returns a new [WatchSignedOut] instance.
  WatchSignedOut({

    required  this.ok,
  });

  @JsonKey(
    
    name: r'ok',
    required: true,
    includeIfNull: false,
  )


  final bool ok;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchSignedOut &&
      other.ok == ok;

    @override
    int get hashCode =>
        ok.hashCode;

  factory WatchSignedOut.fromJson(Map<String, dynamic> json) => _$WatchSignedOutFromJson(json);

  Map<String, dynamic> toJson() => _$WatchSignedOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'glance_flags.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GlanceFlags {
  /// Returns a new [GlanceFlags] instance.
  GlanceFlags({

    required  this.private,

    required  this.hideReplyText,
  });

  @JsonKey(
    
    name: r'private',
    required: true,
    includeIfNull: false,
  )


  final bool private;



  @JsonKey(
    
    name: r'hide_reply_text',
    required: true,
    includeIfNull: false,
  )


  final bool hideReplyText;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GlanceFlags &&
      other.private == private &&
      other.hideReplyText == hideReplyText;

    @override
    int get hashCode =>
        private.hashCode +
        hideReplyText.hashCode;

  factory GlanceFlags.fromJson(Map<String, dynamic> json) => _$GlanceFlagsFromJson(json);

  Map<String, dynamic> toJson() => _$GlanceFlagsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


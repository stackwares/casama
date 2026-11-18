//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_reaction_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetReactionRequest {
  /// Returns a new [SetReactionRequest] instance.
  SetReactionRequest({

    required  this.emoji,
  });

      /// Exactly one emoji (skin tones, flags, keycaps and ZWJ sequences count as one). A text-style pictograph such as ❤ is stored in its emoji form ❤️
  @JsonKey(
    
    name: r'emoji',
    required: true,
    includeIfNull: false,
  )


  final String emoji;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetReactionRequest &&
      other.emoji == emoji;

    @override
    int get hashCode =>
        emoji.hashCode;

  factory SetReactionRequest.fromJson(Map<String, dynamic> json) => _$SetReactionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetReactionRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


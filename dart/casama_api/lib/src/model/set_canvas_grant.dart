//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_canvas_grant.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetCanvasGrant {
  /// Returns a new [SetCanvasGrant] instance.
  SetCanvasGrant({

    required  this.botId,

    required  this.allowed,
  });

  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'allowed',
    required: true,
    includeIfNull: false,
  )


  final bool allowed;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetCanvasGrant &&
      other.botId == botId &&
      other.allowed == allowed;

    @override
    int get hashCode =>
        botId.hashCode +
        allowed.hashCode;

  factory SetCanvasGrant.fromJson(Map<String, dynamic> json) => _$SetCanvasGrantFromJson(json);

  Map<String, dynamic> toJson() => _$SetCanvasGrantToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


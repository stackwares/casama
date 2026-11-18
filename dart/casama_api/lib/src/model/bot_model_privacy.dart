//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_model_privacy.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotModelPrivacy {
  /// Returns a new [BotModelPrivacy] instance.
  BotModelPrivacy({

    required  this.privateModel,
  });

  @JsonKey(
    
    name: r'private_model',
    required: true,
    includeIfNull: false,
  )


  final bool privateModel;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotModelPrivacy &&
      other.privateModel == privateModel;

    @override
    int get hashCode =>
        privateModel.hashCode;

  factory BotModelPrivacy.fromJson(Map<String, dynamic> json) => _$BotModelPrivacyFromJson(json);

  Map<String, dynamic> toJson() => _$BotModelPrivacyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


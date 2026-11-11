//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/bot_secret_request.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_secret_request_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotSecretRequestList {
  /// Returns a new [BotSecretRequestList] instance.
  BotSecretRequestList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<BotSecretRequest> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotSecretRequestList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory BotSecretRequestList.fromJson(Map<String, dynamic> json) => _$BotSecretRequestListFromJson(json);

  Map<String, dynamic> toJson() => _$BotSecretRequestListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


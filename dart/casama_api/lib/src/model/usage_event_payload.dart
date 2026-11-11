//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'usage_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UsageEventPayload {
  /// Returns a new [UsageEventPayload] instance.
  UsageEventPayload({

    required  this.tokensIn,

    required  this.tokensOut,

    required  this.costUsd,
  });

          // minimum: 0
  @JsonKey(
    
    name: r'tokens_in',
    required: true,
    includeIfNull: false,
  )


  final int tokensIn;



          // minimum: 0
  @JsonKey(
    
    name: r'tokens_out',
    required: true,
    includeIfNull: false,
  )


  final int tokensOut;



          // minimum: 0
  @JsonKey(
    
    name: r'cost_usd',
    required: true,
    includeIfNull: false,
  )


  final num costUsd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UsageEventPayload &&
      other.tokensIn == tokensIn &&
      other.tokensOut == tokensOut &&
      other.costUsd == costUsd;

    @override
    int get hashCode =>
        tokensIn.hashCode +
        tokensOut.hashCode +
        costUsd.hashCode;

  factory UsageEventPayload.fromJson(Map<String, dynamic> json) => _$UsageEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$UsageEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


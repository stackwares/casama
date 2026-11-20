//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pinned_live_card.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PinnedLiveCard {
  /// Returns a new [PinnedLiveCard] instance.
  PinnedLiveCard({

    required  this.canvasId,

    required  this.status,
  });

  @JsonKey(
    
    name: r'canvas_id',
    required: true,
    includeIfNull: false,
  )


  final String canvasId;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final PinnedLiveCardStatusEnum status;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PinnedLiveCard &&
      other.canvasId == canvasId &&
      other.status == status;

    @override
    int get hashCode =>
        canvasId.hashCode +
        status.hashCode;

  factory PinnedLiveCard.fromJson(Map<String, dynamic> json) => _$PinnedLiveCardFromJson(json);

  Map<String, dynamic> toJson() => _$PinnedLiveCardToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PinnedLiveCardStatusEnum {
@JsonValue(r'waiting')
waiting(r'waiting'),
@JsonValue(r'shown')
shown(r'shown'),
@JsonValue(r'paused')
paused(r'paused');

const PinnedLiveCardStatusEnum(this.value);

final String value;

@override
String toString() => value;
}



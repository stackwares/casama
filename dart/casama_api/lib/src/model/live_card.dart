//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'live_card.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LiveCard {
  /// Returns a new [LiveCard] instance.
  LiveCard({

    required  this.id,

    required  this.card,

    required  this.fetchedAt,

    required  this.error,

    required  this.pinned,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



      /// The card's component, with its `live` block
  @JsonKey(
    
    name: r'card',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> card;



  @JsonKey(
    
    name: r'fetched_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime fetchedAt;



  @JsonKey(
    
    name: r'error',
    required: true,
    includeIfNull: true,
  )


  final String? error;



  @JsonKey(
    
    name: r'pinned',
    required: true,
    includeIfNull: false,
  )


  final bool pinned;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LiveCard &&
      other.id == id &&
      other.card == card &&
      other.fetchedAt == fetchedAt &&
      other.error == error &&
      other.pinned == pinned;

    @override
    int get hashCode =>
        id.hashCode +
        card.hashCode +
        fetchedAt.hashCode +
        (error == null ? 0 : error.hashCode) +
        pinned.hashCode;

  factory LiveCard.fromJson(Map<String, dynamic> json) => _$LiveCardFromJson(json);

  Map<String, dynamic> toJson() => _$LiveCardToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


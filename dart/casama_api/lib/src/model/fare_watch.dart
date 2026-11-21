//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'fare_watch.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FareWatch {
  /// Returns a new [FareWatch] instance.
  FareWatch({

    required  this.id,

    required  this.cardId,

    required  this.botId,

    required  this.route,

    required  this.below,

    required  this.currency,

    required  this.firstPrice,

    required  this.lastPrice,

    required  this.lastCheckedAt,

    required  this.endsAt,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'card_id',
    required: true,
    includeIfNull: false,
  )


  final String cardId;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: true,
  )


  final String? botId;



  @JsonKey(
    
    name: r'route',
    required: true,
    includeIfNull: false,
  )


  final String route;



  @JsonKey(
    
    name: r'below',
    required: true,
    includeIfNull: true,
  )


  final num? below;



  @JsonKey(
    
    name: r'currency',
    required: true,
    includeIfNull: false,
  )


  final String currency;



  @JsonKey(
    
    name: r'first_price',
    required: true,
    includeIfNull: true,
  )


  final num? firstPrice;



  @JsonKey(
    
    name: r'last_price',
    required: true,
    includeIfNull: true,
  )


  final num? lastPrice;



  @JsonKey(
    
    name: r'last_checked_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? lastCheckedAt;



  @JsonKey(
    
    name: r'ends_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime endsAt;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is FareWatch &&
      other.id == id &&
      other.cardId == cardId &&
      other.botId == botId &&
      other.route == route &&
      other.below == below &&
      other.currency == currency &&
      other.firstPrice == firstPrice &&
      other.lastPrice == lastPrice &&
      other.lastCheckedAt == lastCheckedAt &&
      other.endsAt == endsAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        cardId.hashCode +
        (botId == null ? 0 : botId.hashCode) +
        route.hashCode +
        (below == null ? 0 : below.hashCode) +
        currency.hashCode +
        (firstPrice == null ? 0 : firstPrice.hashCode) +
        (lastPrice == null ? 0 : lastPrice.hashCode) +
        (lastCheckedAt == null ? 0 : lastCheckedAt.hashCode) +
        endsAt.hashCode +
        createdAt.hashCode;

  factory FareWatch.fromJson(Map<String, dynamic> json) => _$FareWatchFromJson(json);

  Map<String, dynamic> toJson() => _$FareWatchToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


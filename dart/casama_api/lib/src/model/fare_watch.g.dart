// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fare_watch.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FareWatchCWProxy {
  FareWatch id(String id);

  FareWatch cardId(String cardId);

  FareWatch botId(String? botId);

  FareWatch route(String route);

  FareWatch below(num? below);

  FareWatch currency(String currency);

  FareWatch firstPrice(num? firstPrice);

  FareWatch lastPrice(num? lastPrice);

  FareWatch lastCheckedAt(DateTime? lastCheckedAt);

  FareWatch endsAt(DateTime endsAt);

  FareWatch createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `FareWatch(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// FareWatch(...).copyWith(id: 12, name: "My name")
  /// ```
  FareWatch call({
    String id,
    String cardId,
    String? botId,
    String route,
    num? below,
    String currency,
    num? firstPrice,
    num? lastPrice,
    DateTime? lastCheckedAt,
    DateTime endsAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfFareWatch.copyWith(...)` or call `instanceOfFareWatch.copyWith.fieldName(value)` for a single field.
class _$FareWatchCWProxyImpl implements _$FareWatchCWProxy {
  const _$FareWatchCWProxyImpl(this._value);

  final FareWatch _value;

  @override
  FareWatch id(String id) => call(id: id);

  @override
  FareWatch cardId(String cardId) => call(cardId: cardId);

  @override
  FareWatch botId(String? botId) => call(botId: botId);

  @override
  FareWatch route(String route) => call(route: route);

  @override
  FareWatch below(num? below) => call(below: below);

  @override
  FareWatch currency(String currency) => call(currency: currency);

  @override
  FareWatch firstPrice(num? firstPrice) => call(firstPrice: firstPrice);

  @override
  FareWatch lastPrice(num? lastPrice) => call(lastPrice: lastPrice);

  @override
  FareWatch lastCheckedAt(DateTime? lastCheckedAt) =>
      call(lastCheckedAt: lastCheckedAt);

  @override
  FareWatch endsAt(DateTime endsAt) => call(endsAt: endsAt);

  @override
  FareWatch createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `FareWatch(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// FareWatch(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  FareWatch call({
    Object? id = const $CopyWithPlaceholder(),
    Object? cardId = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? route = const $CopyWithPlaceholder(),
    Object? below = const $CopyWithPlaceholder(),
    Object? currency = const $CopyWithPlaceholder(),
    Object? firstPrice = const $CopyWithPlaceholder(),
    Object? lastPrice = const $CopyWithPlaceholder(),
    Object? lastCheckedAt = const $CopyWithPlaceholder(),
    Object? endsAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return FareWatch(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      cardId: cardId == const $CopyWithPlaceholder() || cardId == null
          ? _value.cardId
          // ignore: cast_nullable_to_non_nullable
          : cardId as String,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String?,
      route: route == const $CopyWithPlaceholder() || route == null
          ? _value.route
          // ignore: cast_nullable_to_non_nullable
          : route as String,
      below: below == const $CopyWithPlaceholder()
          ? _value.below
          // ignore: cast_nullable_to_non_nullable
          : below as num?,
      currency: currency == const $CopyWithPlaceholder() || currency == null
          ? _value.currency
          // ignore: cast_nullable_to_non_nullable
          : currency as String,
      firstPrice: firstPrice == const $CopyWithPlaceholder()
          ? _value.firstPrice
          // ignore: cast_nullable_to_non_nullable
          : firstPrice as num?,
      lastPrice: lastPrice == const $CopyWithPlaceholder()
          ? _value.lastPrice
          // ignore: cast_nullable_to_non_nullable
          : lastPrice as num?,
      lastCheckedAt: lastCheckedAt == const $CopyWithPlaceholder()
          ? _value.lastCheckedAt
          // ignore: cast_nullable_to_non_nullable
          : lastCheckedAt as DateTime?,
      endsAt: endsAt == const $CopyWithPlaceholder() || endsAt == null
          ? _value.endsAt
          // ignore: cast_nullable_to_non_nullable
          : endsAt as DateTime,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $FareWatchCopyWith on FareWatch {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfFareWatch.copyWith(...)` or `instanceOfFareWatch.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FareWatchCWProxy get copyWith => _$FareWatchCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FareWatch _$FareWatchFromJson(Map<String, dynamic> json) => $checkedCreate(
  'FareWatch',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'card_id',
        'bot_id',
        'route',
        'below',
        'currency',
        'first_price',
        'last_price',
        'last_checked_at',
        'ends_at',
        'created_at',
      ],
    );
    final val = FareWatch(
      id: $checkedConvert('id', (v) => v as String),
      cardId: $checkedConvert('card_id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String?),
      route: $checkedConvert('route', (v) => v as String),
      below: $checkedConvert('below', (v) => v as num?),
      currency: $checkedConvert('currency', (v) => v as String),
      firstPrice: $checkedConvert('first_price', (v) => v as num?),
      lastPrice: $checkedConvert('last_price', (v) => v as num?),
      lastCheckedAt: $checkedConvert(
        'last_checked_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      endsAt: $checkedConvert('ends_at', (v) => DateTime.parse(v as String)),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'cardId': 'card_id',
    'botId': 'bot_id',
    'firstPrice': 'first_price',
    'lastPrice': 'last_price',
    'lastCheckedAt': 'last_checked_at',
    'endsAt': 'ends_at',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$FareWatchToJson(FareWatch instance) => <String, dynamic>{
  'id': instance.id,
  'card_id': instance.cardId,
  'bot_id': instance.botId,
  'route': instance.route,
  'below': instance.below,
  'currency': instance.currency,
  'first_price': instance.firstPrice,
  'last_price': instance.lastPrice,
  'last_checked_at': instance.lastCheckedAt?.toIso8601String(),
  'ends_at': instance.endsAt.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_card.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LiveCardCWProxy {
  LiveCard id(String id);

  LiveCard card(Map<String, Object?> card);

  LiveCard fetchedAt(DateTime fetchedAt);

  LiveCard error(String? error);

  LiveCard pinned(bool pinned);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LiveCard(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LiveCard(...).copyWith(id: 12, name: "My name")
  /// ```
  LiveCard call({
    String id,
    Map<String, Object?> card,
    DateTime fetchedAt,
    String? error,
    bool pinned,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLiveCard.copyWith(...)` or call `instanceOfLiveCard.copyWith.fieldName(value)` for a single field.
class _$LiveCardCWProxyImpl implements _$LiveCardCWProxy {
  const _$LiveCardCWProxyImpl(this._value);

  final LiveCard _value;

  @override
  LiveCard id(String id) => call(id: id);

  @override
  LiveCard card(Map<String, Object?> card) => call(card: card);

  @override
  LiveCard fetchedAt(DateTime fetchedAt) => call(fetchedAt: fetchedAt);

  @override
  LiveCard error(String? error) => call(error: error);

  @override
  LiveCard pinned(bool pinned) => call(pinned: pinned);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LiveCard(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LiveCard(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LiveCard call({
    Object? id = const $CopyWithPlaceholder(),
    Object? card = const $CopyWithPlaceholder(),
    Object? fetchedAt = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
    Object? pinned = const $CopyWithPlaceholder(),
  }) {
    return LiveCard(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      card: card == const $CopyWithPlaceholder() || card == null
          ? _value.card
          // ignore: cast_nullable_to_non_nullable
          : card as Map<String, Object?>,
      fetchedAt: fetchedAt == const $CopyWithPlaceholder() || fetchedAt == null
          ? _value.fetchedAt
          // ignore: cast_nullable_to_non_nullable
          : fetchedAt as DateTime,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
      pinned: pinned == const $CopyWithPlaceholder() || pinned == null
          ? _value.pinned
          // ignore: cast_nullable_to_non_nullable
          : pinned as bool,
    );
  }
}

extension $LiveCardCopyWith on LiveCard {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLiveCard.copyWith(...)` or `instanceOfLiveCard.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LiveCardCWProxy get copyWith => _$LiveCardCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveCard _$LiveCardFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LiveCard', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['id', 'card', 'fetched_at', 'error', 'pinned'],
      );
      final val = LiveCard(
        id: $checkedConvert('id', (v) => v as String),
        card: $checkedConvert('card', (v) => v as Map<String, dynamic>),
        fetchedAt: $checkedConvert(
          'fetched_at',
          (v) => DateTime.parse(v as String),
        ),
        error: $checkedConvert('error', (v) => v as String?),
        pinned: $checkedConvert('pinned', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'fetchedAt': 'fetched_at'});

Map<String, dynamic> _$LiveCardToJson(LiveCard instance) => <String, dynamic>{
  'id': instance.id,
  'card': instance.card,
  'fetched_at': instance.fetchedAt.toIso8601String(),
  'error': instance.error,
  'pinned': instance.pinned,
};

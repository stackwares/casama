// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pinned_live_card.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PinnedLiveCardCWProxy {
  PinnedLiveCard canvasId(String canvasId);

  PinnedLiveCard status(PinnedLiveCardStatusEnum status);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PinnedLiveCard(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PinnedLiveCard(...).copyWith(id: 12, name: "My name")
  /// ```
  PinnedLiveCard call({String canvasId, PinnedLiveCardStatusEnum status});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPinnedLiveCard.copyWith(...)` or call `instanceOfPinnedLiveCard.copyWith.fieldName(value)` for a single field.
class _$PinnedLiveCardCWProxyImpl implements _$PinnedLiveCardCWProxy {
  const _$PinnedLiveCardCWProxyImpl(this._value);

  final PinnedLiveCard _value;

  @override
  PinnedLiveCard canvasId(String canvasId) => call(canvasId: canvasId);

  @override
  PinnedLiveCard status(PinnedLiveCardStatusEnum status) =>
      call(status: status);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PinnedLiveCard(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PinnedLiveCard(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PinnedLiveCard call({
    Object? canvasId = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return PinnedLiveCard(
      canvasId: canvasId == const $CopyWithPlaceholder() || canvasId == null
          ? _value.canvasId
          // ignore: cast_nullable_to_non_nullable
          : canvasId as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as PinnedLiveCardStatusEnum,
    );
  }
}

extension $PinnedLiveCardCopyWith on PinnedLiveCard {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPinnedLiveCard.copyWith(...)` or `instanceOfPinnedLiveCard.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PinnedLiveCardCWProxy get copyWith => _$PinnedLiveCardCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PinnedLiveCard _$PinnedLiveCardFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PinnedLiveCard', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['canvas_id', 'status']);
      final val = PinnedLiveCard(
        canvasId: $checkedConvert('canvas_id', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$PinnedLiveCardStatusEnumEnumMap, v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'canvasId': 'canvas_id'});

Map<String, dynamic> _$PinnedLiveCardToJson(PinnedLiveCard instance) =>
    <String, dynamic>{
      'canvas_id': instance.canvasId,
      'status': _$PinnedLiveCardStatusEnumEnumMap[instance.status]!,
    };

const _$PinnedLiveCardStatusEnumEnumMap = {
  PinnedLiveCardStatusEnum.waiting: 'waiting',
  PinnedLiveCardStatusEnum.shown: 'shown',
  PinnedLiveCardStatusEnum.paused: 'paused',
};

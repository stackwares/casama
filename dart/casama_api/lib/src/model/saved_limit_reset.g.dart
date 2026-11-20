// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_limit_reset.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SavedLimitResetCWProxy {
  SavedLimitReset id(String id);

  SavedLimitReset campaignId(String? campaignId);

  SavedLimitReset message(String message);

  SavedLimitReset expiresAt(DateTime expiresAt);

  SavedLimitReset refillUsd(num refillUsd);

  SavedLimitReset resetDaily(bool resetDaily);

  SavedLimitReset resetComputer(bool resetComputer);

  SavedLimitReset canUse(bool canUse);

  SavedLimitReset unavailableReason(String? unavailableReason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SavedLimitReset(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SavedLimitReset(...).copyWith(id: 12, name: "My name")
  /// ```
  SavedLimitReset call({
    String id,
    String? campaignId,
    String message,
    DateTime expiresAt,
    num refillUsd,
    bool resetDaily,
    bool resetComputer,
    bool canUse,
    String? unavailableReason,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSavedLimitReset.copyWith(...)` or call `instanceOfSavedLimitReset.copyWith.fieldName(value)` for a single field.
class _$SavedLimitResetCWProxyImpl implements _$SavedLimitResetCWProxy {
  const _$SavedLimitResetCWProxyImpl(this._value);

  final SavedLimitReset _value;

  @override
  SavedLimitReset id(String id) => call(id: id);

  @override
  SavedLimitReset campaignId(String? campaignId) =>
      call(campaignId: campaignId);

  @override
  SavedLimitReset message(String message) => call(message: message);

  @override
  SavedLimitReset expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  @override
  SavedLimitReset refillUsd(num refillUsd) => call(refillUsd: refillUsd);

  @override
  SavedLimitReset resetDaily(bool resetDaily) => call(resetDaily: resetDaily);

  @override
  SavedLimitReset resetComputer(bool resetComputer) =>
      call(resetComputer: resetComputer);

  @override
  SavedLimitReset canUse(bool canUse) => call(canUse: canUse);

  @override
  SavedLimitReset unavailableReason(String? unavailableReason) =>
      call(unavailableReason: unavailableReason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SavedLimitReset(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SavedLimitReset(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SavedLimitReset call({
    Object? id = const $CopyWithPlaceholder(),
    Object? campaignId = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? refillUsd = const $CopyWithPlaceholder(),
    Object? resetDaily = const $CopyWithPlaceholder(),
    Object? resetComputer = const $CopyWithPlaceholder(),
    Object? canUse = const $CopyWithPlaceholder(),
    Object? unavailableReason = const $CopyWithPlaceholder(),
  }) {
    return SavedLimitReset(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      campaignId: campaignId == const $CopyWithPlaceholder()
          ? _value.campaignId
          // ignore: cast_nullable_to_non_nullable
          : campaignId as String?,
      message: message == const $CopyWithPlaceholder() || message == null
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
      refillUsd: refillUsd == const $CopyWithPlaceholder() || refillUsd == null
          ? _value.refillUsd
          // ignore: cast_nullable_to_non_nullable
          : refillUsd as num,
      resetDaily:
          resetDaily == const $CopyWithPlaceholder() || resetDaily == null
          ? _value.resetDaily
          // ignore: cast_nullable_to_non_nullable
          : resetDaily as bool,
      resetComputer:
          resetComputer == const $CopyWithPlaceholder() || resetComputer == null
          ? _value.resetComputer
          // ignore: cast_nullable_to_non_nullable
          : resetComputer as bool,
      canUse: canUse == const $CopyWithPlaceholder() || canUse == null
          ? _value.canUse
          // ignore: cast_nullable_to_non_nullable
          : canUse as bool,
      unavailableReason: unavailableReason == const $CopyWithPlaceholder()
          ? _value.unavailableReason
          // ignore: cast_nullable_to_non_nullable
          : unavailableReason as String?,
    );
  }
}

extension $SavedLimitResetCopyWith on SavedLimitReset {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSavedLimitReset.copyWith(...)` or `instanceOfSavedLimitReset.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SavedLimitResetCWProxy get copyWith => _$SavedLimitResetCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SavedLimitReset _$SavedLimitResetFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SavedLimitReset',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'campaign_id',
            'message',
            'expires_at',
            'refill_usd',
            'reset_daily',
            'reset_computer',
            'can_use',
            'unavailable_reason',
          ],
        );
        final val = SavedLimitReset(
          id: $checkedConvert('id', (v) => v as String),
          campaignId: $checkedConvert('campaign_id', (v) => v as String?),
          message: $checkedConvert('message', (v) => v as String),
          expiresAt: $checkedConvert(
            'expires_at',
            (v) => DateTime.parse(v as String),
          ),
          refillUsd: $checkedConvert('refill_usd', (v) => v as num),
          resetDaily: $checkedConvert('reset_daily', (v) => v as bool),
          resetComputer: $checkedConvert('reset_computer', (v) => v as bool),
          canUse: $checkedConvert('can_use', (v) => v as bool),
          unavailableReason: $checkedConvert(
            'unavailable_reason',
            (v) => v as String?,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'campaignId': 'campaign_id',
        'expiresAt': 'expires_at',
        'refillUsd': 'refill_usd',
        'resetDaily': 'reset_daily',
        'resetComputer': 'reset_computer',
        'canUse': 'can_use',
        'unavailableReason': 'unavailable_reason',
      },
    );

Map<String, dynamic> _$SavedLimitResetToJson(SavedLimitReset instance) =>
    <String, dynamic>{
      'id': instance.id,
      'campaign_id': instance.campaignId,
      'message': instance.message,
      'expires_at': instance.expiresAt.toIso8601String(),
      'refill_usd': instance.refillUsd,
      'reset_daily': instance.resetDaily,
      'reset_computer': instance.resetComputer,
      'can_use': instance.canUse,
      'unavailable_reason': instance.unavailableReason,
    };

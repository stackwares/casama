// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'referral_invites.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReferralInvitesCWProxy {
  ReferralInvites total(int total);

  ReferralInvites used(int used);

  ReferralInvites left(int left);

  ReferralInvites unlocked(bool unlocked);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReferralInvites(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReferralInvites(...).copyWith(id: 12, name: "My name")
  /// ```
  ReferralInvites call({int total, int used, int left, bool unlocked});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReferralInvites.copyWith(...)` or call `instanceOfReferralInvites.copyWith.fieldName(value)` for a single field.
class _$ReferralInvitesCWProxyImpl implements _$ReferralInvitesCWProxy {
  const _$ReferralInvitesCWProxyImpl(this._value);

  final ReferralInvites _value;

  @override
  ReferralInvites total(int total) => call(total: total);

  @override
  ReferralInvites used(int used) => call(used: used);

  @override
  ReferralInvites left(int left) => call(left: left);

  @override
  ReferralInvites unlocked(bool unlocked) => call(unlocked: unlocked);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReferralInvites(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReferralInvites(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReferralInvites call({
    Object? total = const $CopyWithPlaceholder(),
    Object? used = const $CopyWithPlaceholder(),
    Object? left = const $CopyWithPlaceholder(),
    Object? unlocked = const $CopyWithPlaceholder(),
  }) {
    return ReferralInvites(
      total: total == const $CopyWithPlaceholder() || total == null
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as int,
      used: used == const $CopyWithPlaceholder() || used == null
          ? _value.used
          // ignore: cast_nullable_to_non_nullable
          : used as int,
      left: left == const $CopyWithPlaceholder() || left == null
          ? _value.left
          // ignore: cast_nullable_to_non_nullable
          : left as int,
      unlocked: unlocked == const $CopyWithPlaceholder() || unlocked == null
          ? _value.unlocked
          // ignore: cast_nullable_to_non_nullable
          : unlocked as bool,
    );
  }
}

extension $ReferralInvitesCopyWith on ReferralInvites {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReferralInvites.copyWith(...)` or `instanceOfReferralInvites.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReferralInvitesCWProxy get copyWith => _$ReferralInvitesCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReferralInvites _$ReferralInvitesFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReferralInvites', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['total', 'used', 'left', 'unlocked'],
      );
      final val = ReferralInvites(
        total: $checkedConvert('total', (v) => (v as num).toInt()),
        used: $checkedConvert('used', (v) => (v as num).toInt()),
        left: $checkedConvert('left', (v) => (v as num).toInt()),
        unlocked: $checkedConvert('unlocked', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$ReferralInvitesToJson(ReferralInvites instance) =>
    <String, dynamic>{
      'total': instance.total,
      'used': instance.used,
      'left': instance.left,
      'unlocked': instance.unlocked,
    };

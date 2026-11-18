// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'referral.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReferralCWProxy {
  Referral enabled(bool enabled);

  Referral code(String? code);

  Referral link(String? link);

  Referral rewardUsd(num rewardUsd);

  Referral welcomeUsd(num welcomeUsd);

  Referral rewardCap(int rewardCap);

  Referral invited(int invited);

  Referral rewarded(int rewarded);

  Referral pending(int pending);

  Referral earnedUsd(num earnedUsd);

  Referral invitedBy(ReferralInvitedBy? invitedBy);

  Referral redeemUntil(DateTime? redeemUntil);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Referral(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Referral(...).copyWith(id: 12, name: "My name")
  /// ```
  Referral call({
    bool enabled,
    String? code,
    String? link,
    num rewardUsd,
    num welcomeUsd,
    int rewardCap,
    int invited,
    int rewarded,
    int pending,
    num earnedUsd,
    ReferralInvitedBy? invitedBy,
    DateTime? redeemUntil,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReferral.copyWith(...)` or call `instanceOfReferral.copyWith.fieldName(value)` for a single field.
class _$ReferralCWProxyImpl implements _$ReferralCWProxy {
  const _$ReferralCWProxyImpl(this._value);

  final Referral _value;

  @override
  Referral enabled(bool enabled) => call(enabled: enabled);

  @override
  Referral code(String? code) => call(code: code);

  @override
  Referral link(String? link) => call(link: link);

  @override
  Referral rewardUsd(num rewardUsd) => call(rewardUsd: rewardUsd);

  @override
  Referral welcomeUsd(num welcomeUsd) => call(welcomeUsd: welcomeUsd);

  @override
  Referral rewardCap(int rewardCap) => call(rewardCap: rewardCap);

  @override
  Referral invited(int invited) => call(invited: invited);

  @override
  Referral rewarded(int rewarded) => call(rewarded: rewarded);

  @override
  Referral pending(int pending) => call(pending: pending);

  @override
  Referral earnedUsd(num earnedUsd) => call(earnedUsd: earnedUsd);

  @override
  Referral invitedBy(ReferralInvitedBy? invitedBy) =>
      call(invitedBy: invitedBy);

  @override
  Referral redeemUntil(DateTime? redeemUntil) => call(redeemUntil: redeemUntil);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Referral(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Referral(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Referral call({
    Object? enabled = const $CopyWithPlaceholder(),
    Object? code = const $CopyWithPlaceholder(),
    Object? link = const $CopyWithPlaceholder(),
    Object? rewardUsd = const $CopyWithPlaceholder(),
    Object? welcomeUsd = const $CopyWithPlaceholder(),
    Object? rewardCap = const $CopyWithPlaceholder(),
    Object? invited = const $CopyWithPlaceholder(),
    Object? rewarded = const $CopyWithPlaceholder(),
    Object? pending = const $CopyWithPlaceholder(),
    Object? earnedUsd = const $CopyWithPlaceholder(),
    Object? invitedBy = const $CopyWithPlaceholder(),
    Object? redeemUntil = const $CopyWithPlaceholder(),
  }) {
    return Referral(
      enabled: enabled == const $CopyWithPlaceholder() || enabled == null
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String?,
      link: link == const $CopyWithPlaceholder()
          ? _value.link
          // ignore: cast_nullable_to_non_nullable
          : link as String?,
      rewardUsd: rewardUsd == const $CopyWithPlaceholder() || rewardUsd == null
          ? _value.rewardUsd
          // ignore: cast_nullable_to_non_nullable
          : rewardUsd as num,
      welcomeUsd:
          welcomeUsd == const $CopyWithPlaceholder() || welcomeUsd == null
          ? _value.welcomeUsd
          // ignore: cast_nullable_to_non_nullable
          : welcomeUsd as num,
      rewardCap: rewardCap == const $CopyWithPlaceholder() || rewardCap == null
          ? _value.rewardCap
          // ignore: cast_nullable_to_non_nullable
          : rewardCap as int,
      invited: invited == const $CopyWithPlaceholder() || invited == null
          ? _value.invited
          // ignore: cast_nullable_to_non_nullable
          : invited as int,
      rewarded: rewarded == const $CopyWithPlaceholder() || rewarded == null
          ? _value.rewarded
          // ignore: cast_nullable_to_non_nullable
          : rewarded as int,
      pending: pending == const $CopyWithPlaceholder() || pending == null
          ? _value.pending
          // ignore: cast_nullable_to_non_nullable
          : pending as int,
      earnedUsd: earnedUsd == const $CopyWithPlaceholder() || earnedUsd == null
          ? _value.earnedUsd
          // ignore: cast_nullable_to_non_nullable
          : earnedUsd as num,
      invitedBy: invitedBy == const $CopyWithPlaceholder()
          ? _value.invitedBy
          // ignore: cast_nullable_to_non_nullable
          : invitedBy as ReferralInvitedBy?,
      redeemUntil: redeemUntil == const $CopyWithPlaceholder()
          ? _value.redeemUntil
          // ignore: cast_nullable_to_non_nullable
          : redeemUntil as DateTime?,
    );
  }
}

extension $ReferralCopyWith on Referral {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReferral.copyWith(...)` or `instanceOfReferral.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReferralCWProxy get copyWith => _$ReferralCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Referral _$ReferralFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Referral',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'enabled',
        'code',
        'link',
        'reward_usd',
        'welcome_usd',
        'reward_cap',
        'invited',
        'rewarded',
        'pending',
        'earned_usd',
        'invited_by',
        'redeem_until',
      ],
    );
    final val = Referral(
      enabled: $checkedConvert('enabled', (v) => v as bool),
      code: $checkedConvert('code', (v) => v as String?),
      link: $checkedConvert('link', (v) => v as String?),
      rewardUsd: $checkedConvert('reward_usd', (v) => v as num),
      welcomeUsd: $checkedConvert('welcome_usd', (v) => v as num),
      rewardCap: $checkedConvert('reward_cap', (v) => (v as num).toInt()),
      invited: $checkedConvert('invited', (v) => (v as num).toInt()),
      rewarded: $checkedConvert('rewarded', (v) => (v as num).toInt()),
      pending: $checkedConvert('pending', (v) => (v as num).toInt()),
      earnedUsd: $checkedConvert('earned_usd', (v) => v as num),
      invitedBy: $checkedConvert(
        'invited_by',
        (v) => v == null
            ? null
            : ReferralInvitedBy.fromJson(v as Map<String, dynamic>),
      ),
      redeemUntil: $checkedConvert(
        'redeem_until',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'rewardUsd': 'reward_usd',
    'welcomeUsd': 'welcome_usd',
    'rewardCap': 'reward_cap',
    'earnedUsd': 'earned_usd',
    'invitedBy': 'invited_by',
    'redeemUntil': 'redeem_until',
  },
);

Map<String, dynamic> _$ReferralToJson(Referral instance) => <String, dynamic>{
  'enabled': instance.enabled,
  'code': instance.code,
  'link': instance.link,
  'reward_usd': instance.rewardUsd,
  'welcome_usd': instance.welcomeUsd,
  'reward_cap': instance.rewardCap,
  'invited': instance.invited,
  'rewarded': instance.rewarded,
  'pending': instance.pending,
  'earned_usd': instance.earnedUsd,
  'invited_by': instance.invitedBy?.toJson(),
  'redeem_until': instance.redeemUntil?.toIso8601String(),
};

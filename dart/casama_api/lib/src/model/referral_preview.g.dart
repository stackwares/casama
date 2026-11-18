// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'referral_preview.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReferralPreviewCWProxy {
  ReferralPreview inviterName(String? inviterName);

  ReferralPreview rewardUsd(num rewardUsd);

  ReferralPreview welcomeUsd(num welcomeUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReferralPreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReferralPreview(...).copyWith(id: 12, name: "My name")
  /// ```
  ReferralPreview call({String? inviterName, num rewardUsd, num welcomeUsd});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReferralPreview.copyWith(...)` or call `instanceOfReferralPreview.copyWith.fieldName(value)` for a single field.
class _$ReferralPreviewCWProxyImpl implements _$ReferralPreviewCWProxy {
  const _$ReferralPreviewCWProxyImpl(this._value);

  final ReferralPreview _value;

  @override
  ReferralPreview inviterName(String? inviterName) =>
      call(inviterName: inviterName);

  @override
  ReferralPreview rewardUsd(num rewardUsd) => call(rewardUsd: rewardUsd);

  @override
  ReferralPreview welcomeUsd(num welcomeUsd) => call(welcomeUsd: welcomeUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReferralPreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReferralPreview(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReferralPreview call({
    Object? inviterName = const $CopyWithPlaceholder(),
    Object? rewardUsd = const $CopyWithPlaceholder(),
    Object? welcomeUsd = const $CopyWithPlaceholder(),
  }) {
    return ReferralPreview(
      inviterName: inviterName == const $CopyWithPlaceholder()
          ? _value.inviterName
          // ignore: cast_nullable_to_non_nullable
          : inviterName as String?,
      rewardUsd: rewardUsd == const $CopyWithPlaceholder() || rewardUsd == null
          ? _value.rewardUsd
          // ignore: cast_nullable_to_non_nullable
          : rewardUsd as num,
      welcomeUsd:
          welcomeUsd == const $CopyWithPlaceholder() || welcomeUsd == null
          ? _value.welcomeUsd
          // ignore: cast_nullable_to_non_nullable
          : welcomeUsd as num,
    );
  }
}

extension $ReferralPreviewCopyWith on ReferralPreview {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReferralPreview.copyWith(...)` or `instanceOfReferralPreview.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReferralPreviewCWProxy get copyWith => _$ReferralPreviewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReferralPreview _$ReferralPreviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReferralPreview',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['inviter_name', 'reward_usd', 'welcome_usd'],
        );
        final val = ReferralPreview(
          inviterName: $checkedConvert('inviter_name', (v) => v as String?),
          rewardUsd: $checkedConvert('reward_usd', (v) => v as num),
          welcomeUsd: $checkedConvert('welcome_usd', (v) => v as num),
        );
        return val;
      },
      fieldKeyMap: const {
        'inviterName': 'inviter_name',
        'rewardUsd': 'reward_usd',
        'welcomeUsd': 'welcome_usd',
      },
    );

Map<String, dynamic> _$ReferralPreviewToJson(ReferralPreview instance) =>
    <String, dynamic>{
      'inviter_name': instance.inviterName,
      'reward_usd': instance.rewardUsd,
      'welcome_usd': instance.welcomeUsd,
    };

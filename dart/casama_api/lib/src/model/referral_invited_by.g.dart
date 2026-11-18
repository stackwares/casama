// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'referral_invited_by.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReferralInvitedByCWProxy {
  ReferralInvitedBy name(String? name);

  ReferralInvitedBy welcomeEarnedUsd(num? welcomeEarnedUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReferralInvitedBy(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReferralInvitedBy(...).copyWith(id: 12, name: "My name")
  /// ```
  ReferralInvitedBy call({String? name, num? welcomeEarnedUsd});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReferralInvitedBy.copyWith(...)` or call `instanceOfReferralInvitedBy.copyWith.fieldName(value)` for a single field.
class _$ReferralInvitedByCWProxyImpl implements _$ReferralInvitedByCWProxy {
  const _$ReferralInvitedByCWProxyImpl(this._value);

  final ReferralInvitedBy _value;

  @override
  ReferralInvitedBy name(String? name) => call(name: name);

  @override
  ReferralInvitedBy welcomeEarnedUsd(num? welcomeEarnedUsd) =>
      call(welcomeEarnedUsd: welcomeEarnedUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReferralInvitedBy(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReferralInvitedBy(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReferralInvitedBy call({
    Object? name = const $CopyWithPlaceholder(),
    Object? welcomeEarnedUsd = const $CopyWithPlaceholder(),
  }) {
    return ReferralInvitedBy(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      welcomeEarnedUsd: welcomeEarnedUsd == const $CopyWithPlaceholder()
          ? _value.welcomeEarnedUsd
          // ignore: cast_nullable_to_non_nullable
          : welcomeEarnedUsd as num?,
    );
  }
}

extension $ReferralInvitedByCopyWith on ReferralInvitedBy {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReferralInvitedBy.copyWith(...)` or `instanceOfReferralInvitedBy.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReferralInvitedByCWProxy get copyWith =>
      _$ReferralInvitedByCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReferralInvitedBy _$ReferralInvitedByFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReferralInvitedBy', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name', 'welcome_earned_usd']);
      final val = ReferralInvitedBy(
        name: $checkedConvert('name', (v) => v as String?),
        welcomeEarnedUsd: $checkedConvert(
          'welcome_earned_usd',
          (v) => v as num?,
        ),
      );
      return val;
    }, fieldKeyMap: const {'welcomeEarnedUsd': 'welcome_earned_usd'});

Map<String, dynamic> _$ReferralInvitedByToJson(ReferralInvitedBy instance) =>
    <String, dynamic>{
      'name': instance.name,
      'welcome_earned_usd': instance.welcomeEarnedUsd,
    };

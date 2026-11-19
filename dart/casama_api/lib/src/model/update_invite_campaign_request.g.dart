// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_invite_campaign_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateInviteCampaignRequestCWProxy {
  UpdateInviteCampaignRequest label(String? label);

  UpdateInviteCampaignRequest maxUses(int? maxUses);

  UpdateInviteCampaignRequest perDay(int? perDay);

  UpdateInviteCampaignRequest startsAt(DateTime? startsAt);

  UpdateInviteCampaignRequest expiresAt(DateTime? expiresAt);

  UpdateInviteCampaignRequest disabled(bool? disabled);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateInviteCampaignRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateInviteCampaignRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateInviteCampaignRequest call({
    String? label,
    int? maxUses,
    int? perDay,
    DateTime? startsAt,
    DateTime? expiresAt,
    bool? disabled,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateInviteCampaignRequest.copyWith(...)` or call `instanceOfUpdateInviteCampaignRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateInviteCampaignRequestCWProxyImpl
    implements _$UpdateInviteCampaignRequestCWProxy {
  const _$UpdateInviteCampaignRequestCWProxyImpl(this._value);

  final UpdateInviteCampaignRequest _value;

  @override
  UpdateInviteCampaignRequest label(String? label) => call(label: label);

  @override
  UpdateInviteCampaignRequest maxUses(int? maxUses) => call(maxUses: maxUses);

  @override
  UpdateInviteCampaignRequest perDay(int? perDay) => call(perDay: perDay);

  @override
  UpdateInviteCampaignRequest startsAt(DateTime? startsAt) =>
      call(startsAt: startsAt);

  @override
  UpdateInviteCampaignRequest expiresAt(DateTime? expiresAt) =>
      call(expiresAt: expiresAt);

  @override
  UpdateInviteCampaignRequest disabled(bool? disabled) =>
      call(disabled: disabled);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateInviteCampaignRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateInviteCampaignRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateInviteCampaignRequest call({
    Object? label = const $CopyWithPlaceholder(),
    Object? maxUses = const $CopyWithPlaceholder(),
    Object? perDay = const $CopyWithPlaceholder(),
    Object? startsAt = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? disabled = const $CopyWithPlaceholder(),
  }) {
    return UpdateInviteCampaignRequest(
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String?,
      maxUses: maxUses == const $CopyWithPlaceholder()
          ? _value.maxUses
          // ignore: cast_nullable_to_non_nullable
          : maxUses as int?,
      perDay: perDay == const $CopyWithPlaceholder()
          ? _value.perDay
          // ignore: cast_nullable_to_non_nullable
          : perDay as int?,
      startsAt: startsAt == const $CopyWithPlaceholder()
          ? _value.startsAt
          // ignore: cast_nullable_to_non_nullable
          : startsAt as DateTime?,
      expiresAt: expiresAt == const $CopyWithPlaceholder()
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime?,
      disabled: disabled == const $CopyWithPlaceholder()
          ? _value.disabled
          // ignore: cast_nullable_to_non_nullable
          : disabled as bool?,
    );
  }
}

extension $UpdateInviteCampaignRequestCopyWith on UpdateInviteCampaignRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateInviteCampaignRequest.copyWith(...)` or `instanceOfUpdateInviteCampaignRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateInviteCampaignRequestCWProxy get copyWith =>
      _$UpdateInviteCampaignRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateInviteCampaignRequest _$UpdateInviteCampaignRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'UpdateInviteCampaignRequest',
  json,
  ($checkedConvert) {
    final val = UpdateInviteCampaignRequest(
      label: $checkedConvert('label', (v) => v as String?),
      maxUses: $checkedConvert('max_uses', (v) => (v as num?)?.toInt()),
      perDay: $checkedConvert('per_day', (v) => (v as num?)?.toInt()),
      startsAt: $checkedConvert(
        'starts_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      disabled: $checkedConvert('disabled', (v) => v as bool?),
    );
    return val;
  },
  fieldKeyMap: const {
    'maxUses': 'max_uses',
    'perDay': 'per_day',
    'startsAt': 'starts_at',
    'expiresAt': 'expires_at',
  },
);

Map<String, dynamic> _$UpdateInviteCampaignRequestToJson(
  UpdateInviteCampaignRequest instance,
) => <String, dynamic>{
  'label': ?instance.label,
  'max_uses': ?instance.maxUses,
  'per_day': ?instance.perDay,
  'starts_at': ?instance.startsAt?.toIso8601String(),
  'expires_at': ?instance.expiresAt?.toIso8601String(),
  'disabled': ?instance.disabled,
};

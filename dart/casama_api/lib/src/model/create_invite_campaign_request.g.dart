// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_invite_campaign_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateInviteCampaignRequestCWProxy {
  CreateInviteCampaignRequest code(String code);

  CreateInviteCampaignRequest label(String label);

  CreateInviteCampaignRequest maxUses(int maxUses);

  CreateInviteCampaignRequest perDay(int? perDay);

  CreateInviteCampaignRequest startsAt(DateTime? startsAt);

  CreateInviteCampaignRequest expiresAt(DateTime? expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateInviteCampaignRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateInviteCampaignRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateInviteCampaignRequest call({
    String code,
    String label,
    int maxUses,
    int? perDay,
    DateTime? startsAt,
    DateTime? expiresAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateInviteCampaignRequest.copyWith(...)` or call `instanceOfCreateInviteCampaignRequest.copyWith.fieldName(value)` for a single field.
class _$CreateInviteCampaignRequestCWProxyImpl
    implements _$CreateInviteCampaignRequestCWProxy {
  const _$CreateInviteCampaignRequestCWProxyImpl(this._value);

  final CreateInviteCampaignRequest _value;

  @override
  CreateInviteCampaignRequest code(String code) => call(code: code);

  @override
  CreateInviteCampaignRequest label(String label) => call(label: label);

  @override
  CreateInviteCampaignRequest maxUses(int maxUses) => call(maxUses: maxUses);

  @override
  CreateInviteCampaignRequest perDay(int? perDay) => call(perDay: perDay);

  @override
  CreateInviteCampaignRequest startsAt(DateTime? startsAt) =>
      call(startsAt: startsAt);

  @override
  CreateInviteCampaignRequest expiresAt(DateTime? expiresAt) =>
      call(expiresAt: expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateInviteCampaignRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateInviteCampaignRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateInviteCampaignRequest call({
    Object? code = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? maxUses = const $CopyWithPlaceholder(),
    Object? perDay = const $CopyWithPlaceholder(),
    Object? startsAt = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
  }) {
    return CreateInviteCampaignRequest(
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      maxUses: maxUses == const $CopyWithPlaceholder() || maxUses == null
          ? _value.maxUses
          // ignore: cast_nullable_to_non_nullable
          : maxUses as int,
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
    );
  }
}

extension $CreateInviteCampaignRequestCopyWith on CreateInviteCampaignRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateInviteCampaignRequest.copyWith(...)` or `instanceOfCreateInviteCampaignRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateInviteCampaignRequestCWProxy get copyWith =>
      _$CreateInviteCampaignRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateInviteCampaignRequest _$CreateInviteCampaignRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CreateInviteCampaignRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['code', 'label', 'max_uses']);
    final val = CreateInviteCampaignRequest(
      code: $checkedConvert('code', (v) => v as String),
      label: $checkedConvert('label', (v) => v as String),
      maxUses: $checkedConvert('max_uses', (v) => (v as num).toInt()),
      perDay: $checkedConvert('per_day', (v) => (v as num?)?.toInt()),
      startsAt: $checkedConvert(
        'starts_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
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

Map<String, dynamic> _$CreateInviteCampaignRequestToJson(
  CreateInviteCampaignRequest instance,
) => <String, dynamic>{
  'code': instance.code,
  'label': instance.label,
  'max_uses': instance.maxUses,
  'per_day': ?instance.perDay,
  'starts_at': ?instance.startsAt?.toIso8601String(),
  'expires_at': ?instance.expiresAt?.toIso8601String(),
};

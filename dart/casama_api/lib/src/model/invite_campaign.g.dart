// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_campaign.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InviteCampaignCWProxy {
  InviteCampaign code(String code);

  InviteCampaign label(String label);

  InviteCampaign maxUses(int maxUses);

  InviteCampaign used(int used);

  InviteCampaign perDay(int? perDay);

  InviteCampaign startsAt(DateTime? startsAt);

  InviteCampaign expiresAt(DateTime? expiresAt);

  InviteCampaign disabled(bool disabled);

  InviteCampaign createdAt(DateTime createdAt);

  InviteCampaign link(String link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteCampaign(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteCampaign(...).copyWith(id: 12, name: "My name")
  /// ```
  InviteCampaign call({
    String code,
    String label,
    int maxUses,
    int used,
    int? perDay,
    DateTime? startsAt,
    DateTime? expiresAt,
    bool disabled,
    DateTime createdAt,
    String link,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInviteCampaign.copyWith(...)` or call `instanceOfInviteCampaign.copyWith.fieldName(value)` for a single field.
class _$InviteCampaignCWProxyImpl implements _$InviteCampaignCWProxy {
  const _$InviteCampaignCWProxyImpl(this._value);

  final InviteCampaign _value;

  @override
  InviteCampaign code(String code) => call(code: code);

  @override
  InviteCampaign label(String label) => call(label: label);

  @override
  InviteCampaign maxUses(int maxUses) => call(maxUses: maxUses);

  @override
  InviteCampaign used(int used) => call(used: used);

  @override
  InviteCampaign perDay(int? perDay) => call(perDay: perDay);

  @override
  InviteCampaign startsAt(DateTime? startsAt) => call(startsAt: startsAt);

  @override
  InviteCampaign expiresAt(DateTime? expiresAt) => call(expiresAt: expiresAt);

  @override
  InviteCampaign disabled(bool disabled) => call(disabled: disabled);

  @override
  InviteCampaign createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  InviteCampaign link(String link) => call(link: link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteCampaign(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteCampaign(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  InviteCampaign call({
    Object? code = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? maxUses = const $CopyWithPlaceholder(),
    Object? used = const $CopyWithPlaceholder(),
    Object? perDay = const $CopyWithPlaceholder(),
    Object? startsAt = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? disabled = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? link = const $CopyWithPlaceholder(),
  }) {
    return InviteCampaign(
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
      used: used == const $CopyWithPlaceholder() || used == null
          ? _value.used
          // ignore: cast_nullable_to_non_nullable
          : used as int,
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
      disabled: disabled == const $CopyWithPlaceholder() || disabled == null
          ? _value.disabled
          // ignore: cast_nullable_to_non_nullable
          : disabled as bool,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      link: link == const $CopyWithPlaceholder() || link == null
          ? _value.link
          // ignore: cast_nullable_to_non_nullable
          : link as String,
    );
  }
}

extension $InviteCampaignCopyWith on InviteCampaign {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInviteCampaign.copyWith(...)` or `instanceOfInviteCampaign.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InviteCampaignCWProxy get copyWith => _$InviteCampaignCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InviteCampaign _$InviteCampaignFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'InviteCampaign',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'code',
            'label',
            'max_uses',
            'used',
            'per_day',
            'starts_at',
            'expires_at',
            'disabled',
            'created_at',
            'link',
          ],
        );
        final val = InviteCampaign(
          code: $checkedConvert('code', (v) => v as String),
          label: $checkedConvert('label', (v) => v as String),
          maxUses: $checkedConvert('max_uses', (v) => (v as num).toInt()),
          used: $checkedConvert('used', (v) => (v as num).toInt()),
          perDay: $checkedConvert('per_day', (v) => (v as num?)?.toInt()),
          startsAt: $checkedConvert(
            'starts_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          expiresAt: $checkedConvert(
            'expires_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          disabled: $checkedConvert('disabled', (v) => v as bool),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          link: $checkedConvert('link', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'maxUses': 'max_uses',
        'perDay': 'per_day',
        'startsAt': 'starts_at',
        'expiresAt': 'expires_at',
        'createdAt': 'created_at',
      },
    );

Map<String, dynamic> _$InviteCampaignToJson(InviteCampaign instance) =>
    <String, dynamic>{
      'code': instance.code,
      'label': instance.label,
      'max_uses': instance.maxUses,
      'used': instance.used,
      'per_day': instance.perDay,
      'starts_at': instance.startsAt?.toIso8601String(),
      'expires_at': instance.expiresAt?.toIso8601String(),
      'disabled': instance.disabled,
      'created_at': instance.createdAt.toIso8601String(),
      'link': instance.link,
    };

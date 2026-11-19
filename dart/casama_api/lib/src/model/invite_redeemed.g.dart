// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_redeemed.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InviteRedeemedCWProxy {
  InviteRedeemed outcome(InviteRedeemedOutcomeEnum outcome);

  InviteRedeemed kind(InviteRedeemedKindEnum kind);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteRedeemed(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteRedeemed(...).copyWith(id: 12, name: "My name")
  /// ```
  InviteRedeemed call({
    InviteRedeemedOutcomeEnum outcome,
    InviteRedeemedKindEnum kind,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInviteRedeemed.copyWith(...)` or call `instanceOfInviteRedeemed.copyWith.fieldName(value)` for a single field.
class _$InviteRedeemedCWProxyImpl implements _$InviteRedeemedCWProxy {
  const _$InviteRedeemedCWProxyImpl(this._value);

  final InviteRedeemed _value;

  @override
  InviteRedeemed outcome(InviteRedeemedOutcomeEnum outcome) =>
      call(outcome: outcome);

  @override
  InviteRedeemed kind(InviteRedeemedKindEnum kind) => call(kind: kind);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteRedeemed(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteRedeemed(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  InviteRedeemed call({
    Object? outcome = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
  }) {
    return InviteRedeemed(
      outcome: outcome == const $CopyWithPlaceholder() || outcome == null
          ? _value.outcome
          // ignore: cast_nullable_to_non_nullable
          : outcome as InviteRedeemedOutcomeEnum,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as InviteRedeemedKindEnum,
    );
  }
}

extension $InviteRedeemedCopyWith on InviteRedeemed {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInviteRedeemed.copyWith(...)` or `instanceOfInviteRedeemed.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InviteRedeemedCWProxy get copyWith => _$InviteRedeemedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InviteRedeemed _$InviteRedeemedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('InviteRedeemed', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['outcome', 'kind']);
      final val = InviteRedeemed(
        outcome: $checkedConvert(
          'outcome',
          (v) => $enumDecode(_$InviteRedeemedOutcomeEnumEnumMap, v),
        ),
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$InviteRedeemedKindEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$InviteRedeemedToJson(InviteRedeemed instance) =>
    <String, dynamic>{
      'outcome': _$InviteRedeemedOutcomeEnumEnumMap[instance.outcome]!,
      'kind': _$InviteRedeemedKindEnumEnumMap[instance.kind]!,
    };

const _$InviteRedeemedOutcomeEnumEnumMap = {
  InviteRedeemedOutcomeEnum.admitted: 'admitted',
  InviteRedeemedOutcomeEnum.waitlisted: 'waitlisted',
};

const _$InviteRedeemedKindEnumEnumMap = {
  InviteRedeemedKindEnum.personal: 'personal',
  InviteRedeemedKindEnum.campaign: 'campaign',
  InviteRedeemedKindEnum.oneTime: 'one_time',
};

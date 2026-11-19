// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_code_preview.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InviteCodePreviewCWProxy {
  InviteCodePreview kind(InviteCodePreviewKindEnum kind);

  InviteCodePreview label(String? label);

  InviteCodePreview inviterName(String? inviterName);

  InviteCodePreview available(bool available);

  InviteCodePreview welcomeUsd(num welcomeUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteCodePreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteCodePreview(...).copyWith(id: 12, name: "My name")
  /// ```
  InviteCodePreview call({
    InviteCodePreviewKindEnum kind,
    String? label,
    String? inviterName,
    bool available,
    num welcomeUsd,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInviteCodePreview.copyWith(...)` or call `instanceOfInviteCodePreview.copyWith.fieldName(value)` for a single field.
class _$InviteCodePreviewCWProxyImpl implements _$InviteCodePreviewCWProxy {
  const _$InviteCodePreviewCWProxyImpl(this._value);

  final InviteCodePreview _value;

  @override
  InviteCodePreview kind(InviteCodePreviewKindEnum kind) => call(kind: kind);

  @override
  InviteCodePreview label(String? label) => call(label: label);

  @override
  InviteCodePreview inviterName(String? inviterName) =>
      call(inviterName: inviterName);

  @override
  InviteCodePreview available(bool available) => call(available: available);

  @override
  InviteCodePreview welcomeUsd(num welcomeUsd) => call(welcomeUsd: welcomeUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteCodePreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteCodePreview(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  InviteCodePreview call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? inviterName = const $CopyWithPlaceholder(),
    Object? available = const $CopyWithPlaceholder(),
    Object? welcomeUsd = const $CopyWithPlaceholder(),
  }) {
    return InviteCodePreview(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as InviteCodePreviewKindEnum,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String?,
      inviterName: inviterName == const $CopyWithPlaceholder()
          ? _value.inviterName
          // ignore: cast_nullable_to_non_nullable
          : inviterName as String?,
      available: available == const $CopyWithPlaceholder() || available == null
          ? _value.available
          // ignore: cast_nullable_to_non_nullable
          : available as bool,
      welcomeUsd:
          welcomeUsd == const $CopyWithPlaceholder() || welcomeUsd == null
          ? _value.welcomeUsd
          // ignore: cast_nullable_to_non_nullable
          : welcomeUsd as num,
    );
  }
}

extension $InviteCodePreviewCopyWith on InviteCodePreview {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInviteCodePreview.copyWith(...)` or `instanceOfInviteCodePreview.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InviteCodePreviewCWProxy get copyWith =>
      _$InviteCodePreviewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InviteCodePreview _$InviteCodePreviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'InviteCodePreview',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'kind',
            'label',
            'inviter_name',
            'available',
            'welcome_usd',
          ],
        );
        final val = InviteCodePreview(
          kind: $checkedConvert(
            'kind',
            (v) => $enumDecode(_$InviteCodePreviewKindEnumEnumMap, v),
          ),
          label: $checkedConvert('label', (v) => v as String?),
          inviterName: $checkedConvert('inviter_name', (v) => v as String?),
          available: $checkedConvert('available', (v) => v as bool),
          welcomeUsd: $checkedConvert('welcome_usd', (v) => v as num),
        );
        return val;
      },
      fieldKeyMap: const {
        'inviterName': 'inviter_name',
        'welcomeUsd': 'welcome_usd',
      },
    );

Map<String, dynamic> _$InviteCodePreviewToJson(InviteCodePreview instance) =>
    <String, dynamic>{
      'kind': _$InviteCodePreviewKindEnumEnumMap[instance.kind]!,
      'label': instance.label,
      'inviter_name': instance.inviterName,
      'available': instance.available,
      'welcome_usd': instance.welcomeUsd,
    };

const _$InviteCodePreviewKindEnumEnumMap = {
  InviteCodePreviewKindEnum.personal: 'personal',
  InviteCodePreviewKindEnum.campaign: 'campaign',
};

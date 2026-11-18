// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_margin_by_kind_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminMarginByKindInnerCWProxy {
  AdminMarginByKindInner kind(String kind);

  AdminMarginByKindInner chargedUsd(num chargedUsd);

  AdminMarginByKindInner chargedTrackedUsd(num chargedTrackedUsd);

  AdminMarginByKindInner upstreamUsd(num upstreamUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMarginByKindInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMarginByKindInner(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminMarginByKindInner call({
    String kind,
    num chargedUsd,
    num chargedTrackedUsd,
    num upstreamUsd,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminMarginByKindInner.copyWith(...)` or call `instanceOfAdminMarginByKindInner.copyWith.fieldName(value)` for a single field.
class _$AdminMarginByKindInnerCWProxyImpl
    implements _$AdminMarginByKindInnerCWProxy {
  const _$AdminMarginByKindInnerCWProxyImpl(this._value);

  final AdminMarginByKindInner _value;

  @override
  AdminMarginByKindInner kind(String kind) => call(kind: kind);

  @override
  AdminMarginByKindInner chargedUsd(num chargedUsd) =>
      call(chargedUsd: chargedUsd);

  @override
  AdminMarginByKindInner chargedTrackedUsd(num chargedTrackedUsd) =>
      call(chargedTrackedUsd: chargedTrackedUsd);

  @override
  AdminMarginByKindInner upstreamUsd(num upstreamUsd) =>
      call(upstreamUsd: upstreamUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMarginByKindInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMarginByKindInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminMarginByKindInner call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? chargedUsd = const $CopyWithPlaceholder(),
    Object? chargedTrackedUsd = const $CopyWithPlaceholder(),
    Object? upstreamUsd = const $CopyWithPlaceholder(),
  }) {
    return AdminMarginByKindInner(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as String,
      chargedUsd:
          chargedUsd == const $CopyWithPlaceholder() || chargedUsd == null
          ? _value.chargedUsd
          // ignore: cast_nullable_to_non_nullable
          : chargedUsd as num,
      chargedTrackedUsd:
          chargedTrackedUsd == const $CopyWithPlaceholder() ||
              chargedTrackedUsd == null
          ? _value.chargedTrackedUsd
          // ignore: cast_nullable_to_non_nullable
          : chargedTrackedUsd as num,
      upstreamUsd:
          upstreamUsd == const $CopyWithPlaceholder() || upstreamUsd == null
          ? _value.upstreamUsd
          // ignore: cast_nullable_to_non_nullable
          : upstreamUsd as num,
    );
  }
}

extension $AdminMarginByKindInnerCopyWith on AdminMarginByKindInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminMarginByKindInner.copyWith(...)` or `instanceOfAdminMarginByKindInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminMarginByKindInnerCWProxy get copyWith =>
      _$AdminMarginByKindInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminMarginByKindInner _$AdminMarginByKindInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'AdminMarginByKindInner',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'kind',
        'charged_usd',
        'charged_tracked_usd',
        'upstream_usd',
      ],
    );
    final val = AdminMarginByKindInner(
      kind: $checkedConvert('kind', (v) => v as String),
      chargedUsd: $checkedConvert('charged_usd', (v) => v as num),
      chargedTrackedUsd: $checkedConvert(
        'charged_tracked_usd',
        (v) => v as num,
      ),
      upstreamUsd: $checkedConvert('upstream_usd', (v) => v as num),
    );
    return val;
  },
  fieldKeyMap: const {
    'chargedUsd': 'charged_usd',
    'chargedTrackedUsd': 'charged_tracked_usd',
    'upstreamUsd': 'upstream_usd',
  },
);

Map<String, dynamic> _$AdminMarginByKindInnerToJson(
  AdminMarginByKindInner instance,
) => <String, dynamic>{
  'kind': instance.kind,
  'charged_usd': instance.chargedUsd,
  'charged_tracked_usd': instance.chargedTrackedUsd,
  'upstream_usd': instance.upstreamUsd,
};

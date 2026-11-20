// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'limit_reset_preview.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LimitResetPreviewCWProxy {
  LimitResetPreview workspaces(int workspaces);

  LimitResetPreview byPlan(Map<String, int> byPlan);

  LimitResetPreview creditsUsd(num creditsUsd);

  LimitResetPreview costUsd(num costUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LimitResetPreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LimitResetPreview(...).copyWith(id: 12, name: "My name")
  /// ```
  LimitResetPreview call({
    int workspaces,
    Map<String, int> byPlan,
    num creditsUsd,
    num costUsd,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLimitResetPreview.copyWith(...)` or call `instanceOfLimitResetPreview.copyWith.fieldName(value)` for a single field.
class _$LimitResetPreviewCWProxyImpl implements _$LimitResetPreviewCWProxy {
  const _$LimitResetPreviewCWProxyImpl(this._value);

  final LimitResetPreview _value;

  @override
  LimitResetPreview workspaces(int workspaces) => call(workspaces: workspaces);

  @override
  LimitResetPreview byPlan(Map<String, int> byPlan) => call(byPlan: byPlan);

  @override
  LimitResetPreview creditsUsd(num creditsUsd) => call(creditsUsd: creditsUsd);

  @override
  LimitResetPreview costUsd(num costUsd) => call(costUsd: costUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LimitResetPreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LimitResetPreview(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LimitResetPreview call({
    Object? workspaces = const $CopyWithPlaceholder(),
    Object? byPlan = const $CopyWithPlaceholder(),
    Object? creditsUsd = const $CopyWithPlaceholder(),
    Object? costUsd = const $CopyWithPlaceholder(),
  }) {
    return LimitResetPreview(
      workspaces:
          workspaces == const $CopyWithPlaceholder() || workspaces == null
          ? _value.workspaces
          // ignore: cast_nullable_to_non_nullable
          : workspaces as int,
      byPlan: byPlan == const $CopyWithPlaceholder() || byPlan == null
          ? _value.byPlan
          // ignore: cast_nullable_to_non_nullable
          : byPlan as Map<String, int>,
      creditsUsd:
          creditsUsd == const $CopyWithPlaceholder() || creditsUsd == null
          ? _value.creditsUsd
          // ignore: cast_nullable_to_non_nullable
          : creditsUsd as num,
      costUsd: costUsd == const $CopyWithPlaceholder() || costUsd == null
          ? _value.costUsd
          // ignore: cast_nullable_to_non_nullable
          : costUsd as num,
    );
  }
}

extension $LimitResetPreviewCopyWith on LimitResetPreview {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLimitResetPreview.copyWith(...)` or `instanceOfLimitResetPreview.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LimitResetPreviewCWProxy get copyWith =>
      _$LimitResetPreviewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LimitResetPreview _$LimitResetPreviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LimitResetPreview',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'workspaces',
            'by_plan',
            'credits_usd',
            'cost_usd',
          ],
        );
        final val = LimitResetPreview(
          workspaces: $checkedConvert('workspaces', (v) => (v as num).toInt()),
          byPlan: $checkedConvert(
            'by_plan',
            (v) => Map<String, int>.from(v as Map),
          ),
          creditsUsd: $checkedConvert('credits_usd', (v) => v as num),
          costUsd: $checkedConvert('cost_usd', (v) => v as num),
        );
        return val;
      },
      fieldKeyMap: const {
        'byPlan': 'by_plan',
        'creditsUsd': 'credits_usd',
        'costUsd': 'cost_usd',
      },
    );

Map<String, dynamic> _$LimitResetPreviewToJson(LimitResetPreview instance) =>
    <String, dynamic>{
      'workspaces': instance.workspaces,
      'by_plan': instance.byPlan,
      'credits_usd': instance.creditsUsd,
      'cost_usd': instance.costUsd,
    };

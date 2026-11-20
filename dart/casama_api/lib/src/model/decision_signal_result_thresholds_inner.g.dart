// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision_signal_result_thresholds_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DecisionSignalResultThresholdsInnerCWProxy {
  DecisionSignalResultThresholdsInner threshold(num threshold);

  DecisionSignalResultThresholdsInner acted(int acted);

  DecisionSignalResultThresholdsInner actedPositive(int actedPositive);

  DecisionSignalResultThresholdsInner actedNegative(int actedNegative);

  DecisionSignalResultThresholdsInner actedSevere(int actedSevere);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSignalResultThresholdsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSignalResultThresholdsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  DecisionSignalResultThresholdsInner call({
    num threshold,
    int acted,
    int actedPositive,
    int actedNegative,
    int actedSevere,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDecisionSignalResultThresholdsInner.copyWith(...)` or call `instanceOfDecisionSignalResultThresholdsInner.copyWith.fieldName(value)` for a single field.
class _$DecisionSignalResultThresholdsInnerCWProxyImpl
    implements _$DecisionSignalResultThresholdsInnerCWProxy {
  const _$DecisionSignalResultThresholdsInnerCWProxyImpl(this._value);

  final DecisionSignalResultThresholdsInner _value;

  @override
  DecisionSignalResultThresholdsInner threshold(num threshold) =>
      call(threshold: threshold);

  @override
  DecisionSignalResultThresholdsInner acted(int acted) => call(acted: acted);

  @override
  DecisionSignalResultThresholdsInner actedPositive(int actedPositive) =>
      call(actedPositive: actedPositive);

  @override
  DecisionSignalResultThresholdsInner actedNegative(int actedNegative) =>
      call(actedNegative: actedNegative);

  @override
  DecisionSignalResultThresholdsInner actedSevere(int actedSevere) =>
      call(actedSevere: actedSevere);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSignalResultThresholdsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSignalResultThresholdsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DecisionSignalResultThresholdsInner call({
    Object? threshold = const $CopyWithPlaceholder(),
    Object? acted = const $CopyWithPlaceholder(),
    Object? actedPositive = const $CopyWithPlaceholder(),
    Object? actedNegative = const $CopyWithPlaceholder(),
    Object? actedSevere = const $CopyWithPlaceholder(),
  }) {
    return DecisionSignalResultThresholdsInner(
      threshold: threshold == const $CopyWithPlaceholder() || threshold == null
          ? _value.threshold
          // ignore: cast_nullable_to_non_nullable
          : threshold as num,
      acted: acted == const $CopyWithPlaceholder() || acted == null
          ? _value.acted
          // ignore: cast_nullable_to_non_nullable
          : acted as int,
      actedPositive:
          actedPositive == const $CopyWithPlaceholder() || actedPositive == null
          ? _value.actedPositive
          // ignore: cast_nullable_to_non_nullable
          : actedPositive as int,
      actedNegative:
          actedNegative == const $CopyWithPlaceholder() || actedNegative == null
          ? _value.actedNegative
          // ignore: cast_nullable_to_non_nullable
          : actedNegative as int,
      actedSevere:
          actedSevere == const $CopyWithPlaceholder() || actedSevere == null
          ? _value.actedSevere
          // ignore: cast_nullable_to_non_nullable
          : actedSevere as int,
    );
  }
}

extension $DecisionSignalResultThresholdsInnerCopyWith
    on DecisionSignalResultThresholdsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDecisionSignalResultThresholdsInner.copyWith(...)` or `instanceOfDecisionSignalResultThresholdsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DecisionSignalResultThresholdsInnerCWProxy get copyWith =>
      _$DecisionSignalResultThresholdsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DecisionSignalResultThresholdsInner
_$DecisionSignalResultThresholdsInnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DecisionSignalResultThresholdsInner',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'threshold',
            'acted',
            'acted_positive',
            'acted_negative',
            'acted_severe',
          ],
        );
        final val = DecisionSignalResultThresholdsInner(
          threshold: $checkedConvert('threshold', (v) => v as num),
          acted: $checkedConvert('acted', (v) => (v as num).toInt()),
          actedPositive: $checkedConvert(
            'acted_positive',
            (v) => (v as num).toInt(),
          ),
          actedNegative: $checkedConvert(
            'acted_negative',
            (v) => (v as num).toInt(),
          ),
          actedSevere: $checkedConvert(
            'acted_severe',
            (v) => (v as num).toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'actedPositive': 'acted_positive',
        'actedNegative': 'acted_negative',
        'actedSevere': 'acted_severe',
      },
    );

Map<String, dynamic> _$DecisionSignalResultThresholdsInnerToJson(
  DecisionSignalResultThresholdsInner instance,
) => <String, dynamic>{
  'threshold': instance.threshold,
  'acted': instance.acted,
  'acted_positive': instance.actedPositive,
  'acted_negative': instance.actedNegative,
  'acted_severe': instance.actedSevere,
};

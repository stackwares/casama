// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision_results.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DecisionResultsCWProxy {
  DecisionResults days(int days);

  DecisionResults items(List<DecisionSignalResult> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionResults(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionResults(...).copyWith(id: 12, name: "My name")
  /// ```
  DecisionResults call({int days, List<DecisionSignalResult> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDecisionResults.copyWith(...)` or call `instanceOfDecisionResults.copyWith.fieldName(value)` for a single field.
class _$DecisionResultsCWProxyImpl implements _$DecisionResultsCWProxy {
  const _$DecisionResultsCWProxyImpl(this._value);

  final DecisionResults _value;

  @override
  DecisionResults days(int days) => call(days: days);

  @override
  DecisionResults items(List<DecisionSignalResult> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionResults(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionResults(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DecisionResults call({
    Object? days = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return DecisionResults(
      days: days == const $CopyWithPlaceholder() || days == null
          ? _value.days
          // ignore: cast_nullable_to_non_nullable
          : days as int,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<DecisionSignalResult>,
    );
  }
}

extension $DecisionResultsCopyWith on DecisionResults {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDecisionResults.copyWith(...)` or `instanceOfDecisionResults.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DecisionResultsCWProxy get copyWith => _$DecisionResultsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DecisionResults _$DecisionResultsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DecisionResults', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['days', 'items']);
      final val = DecisionResults(
        days: $checkedConvert('days', (v) => (v as num).toInt()),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => DecisionSignalResult.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DecisionResultsToJson(DecisionResults instance) =>
    <String, dynamic>{
      'days': instance.days,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

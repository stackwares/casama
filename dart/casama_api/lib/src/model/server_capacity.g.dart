// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_capacity.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ServerCapacityCWProxy {
  ServerCapacity budgetMb(int budgetMb);

  ServerCapacity latest(ServerCapacityLatest? latest);

  ServerCapacity days(List<ServerCapacityDaysInner> days);

  ServerCapacity refusals30d(int refusals30d);

  ServerCapacity fullInWeeks(num? fullInWeeks);

  ServerCapacity alerts(List<ServerCapacityAlertsInner> alerts);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ServerCapacity(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServerCapacity(...).copyWith(id: 12, name: "My name")
  /// ```
  ServerCapacity call({
    int budgetMb,
    ServerCapacityLatest? latest,
    List<ServerCapacityDaysInner> days,
    int refusals30d,
    num? fullInWeeks,
    List<ServerCapacityAlertsInner> alerts,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfServerCapacity.copyWith(...)` or call `instanceOfServerCapacity.copyWith.fieldName(value)` for a single field.
class _$ServerCapacityCWProxyImpl implements _$ServerCapacityCWProxy {
  const _$ServerCapacityCWProxyImpl(this._value);

  final ServerCapacity _value;

  @override
  ServerCapacity budgetMb(int budgetMb) => call(budgetMb: budgetMb);

  @override
  ServerCapacity latest(ServerCapacityLatest? latest) => call(latest: latest);

  @override
  ServerCapacity days(List<ServerCapacityDaysInner> days) => call(days: days);

  @override
  ServerCapacity refusals30d(int refusals30d) => call(refusals30d: refusals30d);

  @override
  ServerCapacity fullInWeeks(num? fullInWeeks) =>
      call(fullInWeeks: fullInWeeks);

  @override
  ServerCapacity alerts(List<ServerCapacityAlertsInner> alerts) =>
      call(alerts: alerts);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ServerCapacity(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServerCapacity(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ServerCapacity call({
    Object? budgetMb = const $CopyWithPlaceholder(),
    Object? latest = const $CopyWithPlaceholder(),
    Object? days = const $CopyWithPlaceholder(),
    Object? refusals30d = const $CopyWithPlaceholder(),
    Object? fullInWeeks = const $CopyWithPlaceholder(),
    Object? alerts = const $CopyWithPlaceholder(),
  }) {
    return ServerCapacity(
      budgetMb: budgetMb == const $CopyWithPlaceholder() || budgetMb == null
          ? _value.budgetMb
          // ignore: cast_nullable_to_non_nullable
          : budgetMb as int,
      latest: latest == const $CopyWithPlaceholder()
          ? _value.latest
          // ignore: cast_nullable_to_non_nullable
          : latest as ServerCapacityLatest?,
      days: days == const $CopyWithPlaceholder() || days == null
          ? _value.days
          // ignore: cast_nullable_to_non_nullable
          : days as List<ServerCapacityDaysInner>,
      refusals30d:
          refusals30d == const $CopyWithPlaceholder() || refusals30d == null
          ? _value.refusals30d
          // ignore: cast_nullable_to_non_nullable
          : refusals30d as int,
      fullInWeeks: fullInWeeks == const $CopyWithPlaceholder()
          ? _value.fullInWeeks
          // ignore: cast_nullable_to_non_nullable
          : fullInWeeks as num?,
      alerts: alerts == const $CopyWithPlaceholder() || alerts == null
          ? _value.alerts
          // ignore: cast_nullable_to_non_nullable
          : alerts as List<ServerCapacityAlertsInner>,
    );
  }
}

extension $ServerCapacityCopyWith on ServerCapacity {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfServerCapacity.copyWith(...)` or `instanceOfServerCapacity.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ServerCapacityCWProxy get copyWith => _$ServerCapacityCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServerCapacity _$ServerCapacityFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ServerCapacity',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'budget_mb',
        'latest',
        'days',
        'refusals_30d',
        'full_in_weeks',
        'alerts',
      ],
    );
    final val = ServerCapacity(
      budgetMb: $checkedConvert('budget_mb', (v) => (v as num).toInt()),
      latest: $checkedConvert(
        'latest',
        (v) => v == null
            ? null
            : ServerCapacityLatest.fromJson(v as Map<String, dynamic>),
      ),
      days: $checkedConvert(
        'days',
        (v) => (v as List<dynamic>)
            .map(
              (e) =>
                  ServerCapacityDaysInner.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      refusals30d: $checkedConvert('refusals_30d', (v) => (v as num).toInt()),
      fullInWeeks: $checkedConvert('full_in_weeks', (v) => v as num?),
      alerts: $checkedConvert(
        'alerts',
        (v) => (v as List<dynamic>)
            .map(
              (e) =>
                  ServerCapacityAlertsInner.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'budgetMb': 'budget_mb',
    'refusals30d': 'refusals_30d',
    'fullInWeeks': 'full_in_weeks',
  },
);

Map<String, dynamic> _$ServerCapacityToJson(ServerCapacity instance) =>
    <String, dynamic>{
      'budget_mb': instance.budgetMb,
      'latest': instance.latest?.toJson(),
      'days': instance.days.map((e) => e.toJson()).toList(),
      'refusals_30d': instance.refusals30d,
      'full_in_weeks': instance.fullInWeeks,
      'alerts': instance.alerts.map((e) => e.toJson()).toList(),
    };

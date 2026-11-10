// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_stats.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SkillStatsCWProxy {
  SkillStats uses(int uses);

  SkillStats successes(int successes);

  SkillStats failures(int failures);

  SkillStats corrections(int corrections);

  SkillStats successRate(num? successRate);

  SkillStats lastFailureAt(DateTime? lastFailureAt);

  SkillStats lastFailureRunId(String? lastFailureRunId);

  SkillStats revisions(List<SkillStatsRevisionsInner> revisions);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SkillStats(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SkillStats(...).copyWith(id: 12, name: "My name")
  /// ```
  SkillStats call({
    int uses,
    int successes,
    int failures,
    int corrections,
    num? successRate,
    DateTime? lastFailureAt,
    String? lastFailureRunId,
    List<SkillStatsRevisionsInner> revisions,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSkillStats.copyWith(...)` or call `instanceOfSkillStats.copyWith.fieldName(value)` for a single field.
class _$SkillStatsCWProxyImpl implements _$SkillStatsCWProxy {
  const _$SkillStatsCWProxyImpl(this._value);

  final SkillStats _value;

  @override
  SkillStats uses(int uses) => call(uses: uses);

  @override
  SkillStats successes(int successes) => call(successes: successes);

  @override
  SkillStats failures(int failures) => call(failures: failures);

  @override
  SkillStats corrections(int corrections) => call(corrections: corrections);

  @override
  SkillStats successRate(num? successRate) => call(successRate: successRate);

  @override
  SkillStats lastFailureAt(DateTime? lastFailureAt) =>
      call(lastFailureAt: lastFailureAt);

  @override
  SkillStats lastFailureRunId(String? lastFailureRunId) =>
      call(lastFailureRunId: lastFailureRunId);

  @override
  SkillStats revisions(List<SkillStatsRevisionsInner> revisions) =>
      call(revisions: revisions);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SkillStats(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SkillStats(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SkillStats call({
    Object? uses = const $CopyWithPlaceholder(),
    Object? successes = const $CopyWithPlaceholder(),
    Object? failures = const $CopyWithPlaceholder(),
    Object? corrections = const $CopyWithPlaceholder(),
    Object? successRate = const $CopyWithPlaceholder(),
    Object? lastFailureAt = const $CopyWithPlaceholder(),
    Object? lastFailureRunId = const $CopyWithPlaceholder(),
    Object? revisions = const $CopyWithPlaceholder(),
  }) {
    return SkillStats(
      uses: uses == const $CopyWithPlaceholder() || uses == null
          ? _value.uses
          // ignore: cast_nullable_to_non_nullable
          : uses as int,
      successes: successes == const $CopyWithPlaceholder() || successes == null
          ? _value.successes
          // ignore: cast_nullable_to_non_nullable
          : successes as int,
      failures: failures == const $CopyWithPlaceholder() || failures == null
          ? _value.failures
          // ignore: cast_nullable_to_non_nullable
          : failures as int,
      corrections:
          corrections == const $CopyWithPlaceholder() || corrections == null
          ? _value.corrections
          // ignore: cast_nullable_to_non_nullable
          : corrections as int,
      successRate: successRate == const $CopyWithPlaceholder()
          ? _value.successRate
          // ignore: cast_nullable_to_non_nullable
          : successRate as num?,
      lastFailureAt: lastFailureAt == const $CopyWithPlaceholder()
          ? _value.lastFailureAt
          // ignore: cast_nullable_to_non_nullable
          : lastFailureAt as DateTime?,
      lastFailureRunId: lastFailureRunId == const $CopyWithPlaceholder()
          ? _value.lastFailureRunId
          // ignore: cast_nullable_to_non_nullable
          : lastFailureRunId as String?,
      revisions: revisions == const $CopyWithPlaceholder() || revisions == null
          ? _value.revisions
          // ignore: cast_nullable_to_non_nullable
          : revisions as List<SkillStatsRevisionsInner>,
    );
  }
}

extension $SkillStatsCopyWith on SkillStats {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSkillStats.copyWith(...)` or `instanceOfSkillStats.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SkillStatsCWProxy get copyWith => _$SkillStatsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkillStats _$SkillStatsFromJson(Map<String, dynamic> json) => $checkedCreate(
  'SkillStats',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'uses',
        'successes',
        'failures',
        'corrections',
        'success_rate',
        'last_failure_at',
        'last_failure_run_id',
        'revisions',
      ],
    );
    final val = SkillStats(
      uses: $checkedConvert('uses', (v) => (v as num).toInt()),
      successes: $checkedConvert('successes', (v) => (v as num).toInt()),
      failures: $checkedConvert('failures', (v) => (v as num).toInt()),
      corrections: $checkedConvert('corrections', (v) => (v as num).toInt()),
      successRate: $checkedConvert('success_rate', (v) => v as num?),
      lastFailureAt: $checkedConvert(
        'last_failure_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      lastFailureRunId: $checkedConvert(
        'last_failure_run_id',
        (v) => v as String?,
      ),
      revisions: $checkedConvert(
        'revisions',
        (v) => (v as List<dynamic>)
            .map(
              (e) =>
                  SkillStatsRevisionsInner.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'successRate': 'success_rate',
    'lastFailureAt': 'last_failure_at',
    'lastFailureRunId': 'last_failure_run_id',
  },
);

Map<String, dynamic> _$SkillStatsToJson(SkillStats instance) =>
    <String, dynamic>{
      'uses': instance.uses,
      'successes': instance.successes,
      'failures': instance.failures,
      'corrections': instance.corrections,
      'success_rate': instance.successRate,
      'last_failure_at': instance.lastFailureAt?.toIso8601String(),
      'last_failure_run_id': instance.lastFailureRunId,
      'revisions': instance.revisions.map((e) => e.toJson()).toList(),
    };

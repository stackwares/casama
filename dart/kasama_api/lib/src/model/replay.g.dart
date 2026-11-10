// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'replay.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReplayCWProxy {
  Replay id(String id);

  Replay botId(String botId);

  Replay name(String name);

  Replay description(String description);

  Replay params(List<ReplayParamInfo> params);

  Replay steps(List<ReplayStepsInner> steps);

  Replay source_(ReplaySource_Enum source_);

  Replay runs(int runs);

  Replay failures(int failures);

  Replay lastFailure(String? lastFailure);

  Replay lastRunAt(DateTime? lastRunAt);

  Replay updatedAt(DateTime updatedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Replay(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Replay(...).copyWith(id: 12, name: "My name")
  /// ```
  Replay call({
    String id,
    String botId,
    String name,
    String description,
    List<ReplayParamInfo> params,
    List<ReplayStepsInner> steps,
    ReplaySource_Enum source_,
    int runs,
    int failures,
    String? lastFailure,
    DateTime? lastRunAt,
    DateTime updatedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReplay.copyWith(...)` or call `instanceOfReplay.copyWith.fieldName(value)` for a single field.
class _$ReplayCWProxyImpl implements _$ReplayCWProxy {
  const _$ReplayCWProxyImpl(this._value);

  final Replay _value;

  @override
  Replay id(String id) => call(id: id);

  @override
  Replay botId(String botId) => call(botId: botId);

  @override
  Replay name(String name) => call(name: name);

  @override
  Replay description(String description) => call(description: description);

  @override
  Replay params(List<ReplayParamInfo> params) => call(params: params);

  @override
  Replay steps(List<ReplayStepsInner> steps) => call(steps: steps);

  @override
  Replay source_(ReplaySource_Enum source_) => call(source_: source_);

  @override
  Replay runs(int runs) => call(runs: runs);

  @override
  Replay failures(int failures) => call(failures: failures);

  @override
  Replay lastFailure(String? lastFailure) => call(lastFailure: lastFailure);

  @override
  Replay lastRunAt(DateTime? lastRunAt) => call(lastRunAt: lastRunAt);

  @override
  Replay updatedAt(DateTime updatedAt) => call(updatedAt: updatedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Replay(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Replay(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Replay call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? params = const $CopyWithPlaceholder(),
    Object? steps = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? runs = const $CopyWithPlaceholder(),
    Object? failures = const $CopyWithPlaceholder(),
    Object? lastFailure = const $CopyWithPlaceholder(),
    Object? lastRunAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
  }) {
    return Replay(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      params: params == const $CopyWithPlaceholder() || params == null
          ? _value.params
          // ignore: cast_nullable_to_non_nullable
          : params as List<ReplayParamInfo>,
      steps: steps == const $CopyWithPlaceholder() || steps == null
          ? _value.steps
          // ignore: cast_nullable_to_non_nullable
          : steps as List<ReplayStepsInner>,
      source_: source_ == const $CopyWithPlaceholder() || source_ == null
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as ReplaySource_Enum,
      runs: runs == const $CopyWithPlaceholder() || runs == null
          ? _value.runs
          // ignore: cast_nullable_to_non_nullable
          : runs as int,
      failures: failures == const $CopyWithPlaceholder() || failures == null
          ? _value.failures
          // ignore: cast_nullable_to_non_nullable
          : failures as int,
      lastFailure: lastFailure == const $CopyWithPlaceholder()
          ? _value.lastFailure
          // ignore: cast_nullable_to_non_nullable
          : lastFailure as String?,
      lastRunAt: lastRunAt == const $CopyWithPlaceholder()
          ? _value.lastRunAt
          // ignore: cast_nullable_to_non_nullable
          : lastRunAt as DateTime?,
      updatedAt: updatedAt == const $CopyWithPlaceholder() || updatedAt == null
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
    );
  }
}

extension $ReplayCopyWith on Replay {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReplay.copyWith(...)` or `instanceOfReplay.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReplayCWProxy get copyWith => _$ReplayCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Replay _$ReplayFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Replay',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'bot_id',
        'name',
        'description',
        'params',
        'steps',
        'source',
        'runs',
        'failures',
        'last_failure',
        'last_run_at',
        'updated_at',
      ],
    );
    final val = Replay(
      id: $checkedConvert('id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      description: $checkedConvert('description', (v) => v as String),
      params: $checkedConvert(
        'params',
        (v) => (v as List<dynamic>)
            .map((e) => ReplayParamInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      steps: $checkedConvert(
        'steps',
        (v) => (v as List<dynamic>)
            .map((e) => ReplayStepsInner.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      source_: $checkedConvert(
        'source',
        (v) => $enumDecode(_$ReplaySource_EnumEnumMap, v),
      ),
      runs: $checkedConvert('runs', (v) => (v as num).toInt()),
      failures: $checkedConvert('failures', (v) => (v as num).toInt()),
      lastFailure: $checkedConvert('last_failure', (v) => v as String?),
      lastRunAt: $checkedConvert(
        'last_run_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      updatedAt: $checkedConvert(
        'updated_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'source_': 'source',
    'lastFailure': 'last_failure',
    'lastRunAt': 'last_run_at',
    'updatedAt': 'updated_at',
  },
);

Map<String, dynamic> _$ReplayToJson(Replay instance) => <String, dynamic>{
  'id': instance.id,
  'bot_id': instance.botId,
  'name': instance.name,
  'description': instance.description,
  'params': instance.params.map((e) => e.toJson()).toList(),
  'steps': instance.steps.map((e) => e.toJson()).toList(),
  'source': _$ReplaySource_EnumEnumMap[instance.source_]!,
  'runs': instance.runs,
  'failures': instance.failures,
  'last_failure': instance.lastFailure,
  'last_run_at': instance.lastRunAt?.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$ReplaySource_EnumEnumMap = {
  ReplaySource_Enum.bot: 'bot',
  ReplaySource_Enum.teach: 'teach',
  ReplaySource_Enum.manual: 'manual',
};

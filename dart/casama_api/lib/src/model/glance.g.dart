// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glance.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GlanceCWProxy {
  Glance version(String version);

  Glance madeAt(DateTime madeAt);

  Glance orgId(String orgId);

  Glance needs(GlanceNeeds needs);

  Glance bots(List<GlanceBot> bots);

  Glance next(List<GlanceRoutine> next);

  Glance routines(List<GlanceRoutineChoice> routines);

  Glance brief(GlanceBrief? brief);

  Glance lately(List<GlanceDone> lately);

  Glance recent(List<GlanceCreation> recent);

  Glance tasks(GlanceTasks tasks);

  Glance credits(GlanceCredits credits);

  Glance starters(List<GlanceStarter> starters);

  Glance flags(GlanceFlags flags);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Glance(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Glance(...).copyWith(id: 12, name: "My name")
  /// ```
  Glance call({
    String version,
    DateTime madeAt,
    String orgId,
    GlanceNeeds needs,
    List<GlanceBot> bots,
    List<GlanceRoutine> next,
    List<GlanceRoutineChoice> routines,
    GlanceBrief? brief,
    List<GlanceDone> lately,
    List<GlanceCreation> recent,
    GlanceTasks tasks,
    GlanceCredits credits,
    List<GlanceStarter> starters,
    GlanceFlags flags,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGlance.copyWith(...)` or call `instanceOfGlance.copyWith.fieldName(value)` for a single field.
class _$GlanceCWProxyImpl implements _$GlanceCWProxy {
  const _$GlanceCWProxyImpl(this._value);

  final Glance _value;

  @override
  Glance version(String version) => call(version: version);

  @override
  Glance madeAt(DateTime madeAt) => call(madeAt: madeAt);

  @override
  Glance orgId(String orgId) => call(orgId: orgId);

  @override
  Glance needs(GlanceNeeds needs) => call(needs: needs);

  @override
  Glance bots(List<GlanceBot> bots) => call(bots: bots);

  @override
  Glance next(List<GlanceRoutine> next) => call(next: next);

  @override
  Glance routines(List<GlanceRoutineChoice> routines) =>
      call(routines: routines);

  @override
  Glance brief(GlanceBrief? brief) => call(brief: brief);

  @override
  Glance lately(List<GlanceDone> lately) => call(lately: lately);

  @override
  Glance recent(List<GlanceCreation> recent) => call(recent: recent);

  @override
  Glance tasks(GlanceTasks tasks) => call(tasks: tasks);

  @override
  Glance credits(GlanceCredits credits) => call(credits: credits);

  @override
  Glance starters(List<GlanceStarter> starters) => call(starters: starters);

  @override
  Glance flags(GlanceFlags flags) => call(flags: flags);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Glance(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Glance(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Glance call({
    Object? version = const $CopyWithPlaceholder(),
    Object? madeAt = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? needs = const $CopyWithPlaceholder(),
    Object? bots = const $CopyWithPlaceholder(),
    Object? next = const $CopyWithPlaceholder(),
    Object? routines = const $CopyWithPlaceholder(),
    Object? brief = const $CopyWithPlaceholder(),
    Object? lately = const $CopyWithPlaceholder(),
    Object? recent = const $CopyWithPlaceholder(),
    Object? tasks = const $CopyWithPlaceholder(),
    Object? credits = const $CopyWithPlaceholder(),
    Object? starters = const $CopyWithPlaceholder(),
    Object? flags = const $CopyWithPlaceholder(),
  }) {
    return Glance(
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as String,
      madeAt: madeAt == const $CopyWithPlaceholder() || madeAt == null
          ? _value.madeAt
          // ignore: cast_nullable_to_non_nullable
          : madeAt as DateTime,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      needs: needs == const $CopyWithPlaceholder() || needs == null
          ? _value.needs
          // ignore: cast_nullable_to_non_nullable
          : needs as GlanceNeeds,
      bots: bots == const $CopyWithPlaceholder() || bots == null
          ? _value.bots
          // ignore: cast_nullable_to_non_nullable
          : bots as List<GlanceBot>,
      next: next == const $CopyWithPlaceholder() || next == null
          ? _value.next
          // ignore: cast_nullable_to_non_nullable
          : next as List<GlanceRoutine>,
      routines: routines == const $CopyWithPlaceholder() || routines == null
          ? _value.routines
          // ignore: cast_nullable_to_non_nullable
          : routines as List<GlanceRoutineChoice>,
      brief: brief == const $CopyWithPlaceholder()
          ? _value.brief
          // ignore: cast_nullable_to_non_nullable
          : brief as GlanceBrief?,
      lately: lately == const $CopyWithPlaceholder() || lately == null
          ? _value.lately
          // ignore: cast_nullable_to_non_nullable
          : lately as List<GlanceDone>,
      recent: recent == const $CopyWithPlaceholder() || recent == null
          ? _value.recent
          // ignore: cast_nullable_to_non_nullable
          : recent as List<GlanceCreation>,
      tasks: tasks == const $CopyWithPlaceholder() || tasks == null
          ? _value.tasks
          // ignore: cast_nullable_to_non_nullable
          : tasks as GlanceTasks,
      credits: credits == const $CopyWithPlaceholder() || credits == null
          ? _value.credits
          // ignore: cast_nullable_to_non_nullable
          : credits as GlanceCredits,
      starters: starters == const $CopyWithPlaceholder() || starters == null
          ? _value.starters
          // ignore: cast_nullable_to_non_nullable
          : starters as List<GlanceStarter>,
      flags: flags == const $CopyWithPlaceholder() || flags == null
          ? _value.flags
          // ignore: cast_nullable_to_non_nullable
          : flags as GlanceFlags,
    );
  }
}

extension $GlanceCopyWith on Glance {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGlance.copyWith(...)` or `instanceOfGlance.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GlanceCWProxy get copyWith => _$GlanceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Glance _$GlanceFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Glance',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'version',
        'made_at',
        'org_id',
        'needs',
        'bots',
        'next',
        'routines',
        'brief',
        'lately',
        'recent',
        'tasks',
        'credits',
        'starters',
        'flags',
      ],
    );
    final val = Glance(
      version: $checkedConvert('version', (v) => v as String),
      madeAt: $checkedConvert('made_at', (v) => DateTime.parse(v as String)),
      orgId: $checkedConvert('org_id', (v) => v as String),
      needs: $checkedConvert(
        'needs',
        (v) => GlanceNeeds.fromJson(v as Map<String, dynamic>),
      ),
      bots: $checkedConvert(
        'bots',
        (v) => (v as List<dynamic>)
            .map((e) => GlanceBot.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      next: $checkedConvert(
        'next',
        (v) => (v as List<dynamic>)
            .map((e) => GlanceRoutine.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      routines: $checkedConvert(
        'routines',
        (v) => (v as List<dynamic>)
            .map((e) => GlanceRoutineChoice.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      brief: $checkedConvert(
        'brief',
        (v) =>
            v == null ? null : GlanceBrief.fromJson(v as Map<String, dynamic>),
      ),
      lately: $checkedConvert(
        'lately',
        (v) => (v as List<dynamic>)
            .map((e) => GlanceDone.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      recent: $checkedConvert(
        'recent',
        (v) => (v as List<dynamic>)
            .map((e) => GlanceCreation.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      tasks: $checkedConvert(
        'tasks',
        (v) => GlanceTasks.fromJson(v as Map<String, dynamic>),
      ),
      credits: $checkedConvert(
        'credits',
        (v) => GlanceCredits.fromJson(v as Map<String, dynamic>),
      ),
      starters: $checkedConvert(
        'starters',
        (v) => (v as List<dynamic>)
            .map((e) => GlanceStarter.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      flags: $checkedConvert(
        'flags',
        (v) => GlanceFlags.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'madeAt': 'made_at', 'orgId': 'org_id'},
);

Map<String, dynamic> _$GlanceToJson(Glance instance) => <String, dynamic>{
  'version': instance.version,
  'made_at': instance.madeAt.toIso8601String(),
  'org_id': instance.orgId,
  'needs': instance.needs.toJson(),
  'bots': instance.bots.map((e) => e.toJson()).toList(),
  'next': instance.next.map((e) => e.toJson()).toList(),
  'routines': instance.routines.map((e) => e.toJson()).toList(),
  'brief': instance.brief?.toJson(),
  'lately': instance.lately.map((e) => e.toJson()).toList(),
  'recent': instance.recent.map((e) => e.toJson()).toList(),
  'tasks': instance.tasks.toJson(),
  'credits': instance.credits.toJson(),
  'starters': instance.starters.map((e) => e.toJson()).toList(),
  'flags': instance.flags.toJson(),
};

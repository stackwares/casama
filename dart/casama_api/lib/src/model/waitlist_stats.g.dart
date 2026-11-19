// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waitlist_stats.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WaitlistStatsCWProxy {
  WaitlistStats waiting(int waiting);

  WaitlistStats queued(int queued);

  WaitlistStats admitted(int admitted);

  WaitlistStats joined(int joined);

  WaitlistStats firstChat(int firstChat);

  WaitlistStats listedToday(int listedToday);

  WaitlistStats admittedToday(int admittedToday);

  WaitlistStats emailsToday(int emailsToday);

  WaitlistStats bySource(List<WaitlistStatsBySourceInner> bySource);

  WaitlistStats byVia(List<WaitlistStatsBySourceInner> byVia);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WaitlistStats(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WaitlistStats(...).copyWith(id: 12, name: "My name")
  /// ```
  WaitlistStats call({
    int waiting,
    int queued,
    int admitted,
    int joined,
    int firstChat,
    int listedToday,
    int admittedToday,
    int emailsToday,
    List<WaitlistStatsBySourceInner> bySource,
    List<WaitlistStatsBySourceInner> byVia,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWaitlistStats.copyWith(...)` or call `instanceOfWaitlistStats.copyWith.fieldName(value)` for a single field.
class _$WaitlistStatsCWProxyImpl implements _$WaitlistStatsCWProxy {
  const _$WaitlistStatsCWProxyImpl(this._value);

  final WaitlistStats _value;

  @override
  WaitlistStats waiting(int waiting) => call(waiting: waiting);

  @override
  WaitlistStats queued(int queued) => call(queued: queued);

  @override
  WaitlistStats admitted(int admitted) => call(admitted: admitted);

  @override
  WaitlistStats joined(int joined) => call(joined: joined);

  @override
  WaitlistStats firstChat(int firstChat) => call(firstChat: firstChat);

  @override
  WaitlistStats listedToday(int listedToday) => call(listedToday: listedToday);

  @override
  WaitlistStats admittedToday(int admittedToday) =>
      call(admittedToday: admittedToday);

  @override
  WaitlistStats emailsToday(int emailsToday) => call(emailsToday: emailsToday);

  @override
  WaitlistStats bySource(List<WaitlistStatsBySourceInner> bySource) =>
      call(bySource: bySource);

  @override
  WaitlistStats byVia(List<WaitlistStatsBySourceInner> byVia) =>
      call(byVia: byVia);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WaitlistStats(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WaitlistStats(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WaitlistStats call({
    Object? waiting = const $CopyWithPlaceholder(),
    Object? queued = const $CopyWithPlaceholder(),
    Object? admitted = const $CopyWithPlaceholder(),
    Object? joined = const $CopyWithPlaceholder(),
    Object? firstChat = const $CopyWithPlaceholder(),
    Object? listedToday = const $CopyWithPlaceholder(),
    Object? admittedToday = const $CopyWithPlaceholder(),
    Object? emailsToday = const $CopyWithPlaceholder(),
    Object? bySource = const $CopyWithPlaceholder(),
    Object? byVia = const $CopyWithPlaceholder(),
  }) {
    return WaitlistStats(
      waiting: waiting == const $CopyWithPlaceholder() || waiting == null
          ? _value.waiting
          // ignore: cast_nullable_to_non_nullable
          : waiting as int,
      queued: queued == const $CopyWithPlaceholder() || queued == null
          ? _value.queued
          // ignore: cast_nullable_to_non_nullable
          : queued as int,
      admitted: admitted == const $CopyWithPlaceholder() || admitted == null
          ? _value.admitted
          // ignore: cast_nullable_to_non_nullable
          : admitted as int,
      joined: joined == const $CopyWithPlaceholder() || joined == null
          ? _value.joined
          // ignore: cast_nullable_to_non_nullable
          : joined as int,
      firstChat: firstChat == const $CopyWithPlaceholder() || firstChat == null
          ? _value.firstChat
          // ignore: cast_nullable_to_non_nullable
          : firstChat as int,
      listedToday:
          listedToday == const $CopyWithPlaceholder() || listedToday == null
          ? _value.listedToday
          // ignore: cast_nullable_to_non_nullable
          : listedToday as int,
      admittedToday:
          admittedToday == const $CopyWithPlaceholder() || admittedToday == null
          ? _value.admittedToday
          // ignore: cast_nullable_to_non_nullable
          : admittedToday as int,
      emailsToday:
          emailsToday == const $CopyWithPlaceholder() || emailsToday == null
          ? _value.emailsToday
          // ignore: cast_nullable_to_non_nullable
          : emailsToday as int,
      bySource: bySource == const $CopyWithPlaceholder() || bySource == null
          ? _value.bySource
          // ignore: cast_nullable_to_non_nullable
          : bySource as List<WaitlistStatsBySourceInner>,
      byVia: byVia == const $CopyWithPlaceholder() || byVia == null
          ? _value.byVia
          // ignore: cast_nullable_to_non_nullable
          : byVia as List<WaitlistStatsBySourceInner>,
    );
  }
}

extension $WaitlistStatsCopyWith on WaitlistStats {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWaitlistStats.copyWith(...)` or `instanceOfWaitlistStats.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WaitlistStatsCWProxy get copyWith => _$WaitlistStatsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WaitlistStats _$WaitlistStatsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'WaitlistStats',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'waiting',
        'queued',
        'admitted',
        'joined',
        'first_chat',
        'listed_today',
        'admitted_today',
        'emails_today',
        'by_source',
        'by_via',
      ],
    );
    final val = WaitlistStats(
      waiting: $checkedConvert('waiting', (v) => (v as num).toInt()),
      queued: $checkedConvert('queued', (v) => (v as num).toInt()),
      admitted: $checkedConvert('admitted', (v) => (v as num).toInt()),
      joined: $checkedConvert('joined', (v) => (v as num).toInt()),
      firstChat: $checkedConvert('first_chat', (v) => (v as num).toInt()),
      listedToday: $checkedConvert('listed_today', (v) => (v as num).toInt()),
      admittedToday: $checkedConvert(
        'admitted_today',
        (v) => (v as num).toInt(),
      ),
      emailsToday: $checkedConvert('emails_today', (v) => (v as num).toInt()),
      bySource: $checkedConvert(
        'by_source',
        (v) => (v as List<dynamic>)
            .map(
              (e) => WaitlistStatsBySourceInner.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
      ),
      byVia: $checkedConvert(
        'by_via',
        (v) => (v as List<dynamic>)
            .map(
              (e) => WaitlistStatsBySourceInner.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'firstChat': 'first_chat',
    'listedToday': 'listed_today',
    'admittedToday': 'admitted_today',
    'emailsToday': 'emails_today',
    'bySource': 'by_source',
    'byVia': 'by_via',
  },
);

Map<String, dynamic> _$WaitlistStatsToJson(WaitlistStats instance) =>
    <String, dynamic>{
      'waiting': instance.waiting,
      'queued': instance.queued,
      'admitted': instance.admitted,
      'joined': instance.joined,
      'first_chat': instance.firstChat,
      'listed_today': instance.listedToday,
      'admitted_today': instance.admittedToday,
      'emails_today': instance.emailsToday,
      'by_source': instance.bySource.map((e) => e.toJson()).toList(),
      'by_via': instance.byVia.map((e) => e.toJson()).toList(),
    };

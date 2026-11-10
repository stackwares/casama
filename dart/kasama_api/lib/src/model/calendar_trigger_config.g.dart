// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_trigger_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CalendarTriggerConfigCWProxy {
  CalendarTriggerConfig integrationId(String integrationId);

  CalendarTriggerConfig offsetMinutes(int offsetMinutes);

  CalendarTriggerConfig calendar(String? calendar);

  CalendarTriggerConfig outsideGuests(bool? outsideGuests);

  CalendarTriggerConfig titleMatch(String? titleMatch);

  CalendarTriggerConfig hasVideoLink(bool? hasVideoLink);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CalendarTriggerConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CalendarTriggerConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  CalendarTriggerConfig call({
    String integrationId,
    int offsetMinutes,
    String? calendar,
    bool? outsideGuests,
    String? titleMatch,
    bool? hasVideoLink,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCalendarTriggerConfig.copyWith(...)` or call `instanceOfCalendarTriggerConfig.copyWith.fieldName(value)` for a single field.
class _$CalendarTriggerConfigCWProxyImpl
    implements _$CalendarTriggerConfigCWProxy {
  const _$CalendarTriggerConfigCWProxyImpl(this._value);

  final CalendarTriggerConfig _value;

  @override
  CalendarTriggerConfig integrationId(String integrationId) =>
      call(integrationId: integrationId);

  @override
  CalendarTriggerConfig offsetMinutes(int offsetMinutes) =>
      call(offsetMinutes: offsetMinutes);

  @override
  CalendarTriggerConfig calendar(String? calendar) => call(calendar: calendar);

  @override
  CalendarTriggerConfig outsideGuests(bool? outsideGuests) =>
      call(outsideGuests: outsideGuests);

  @override
  CalendarTriggerConfig titleMatch(String? titleMatch) =>
      call(titleMatch: titleMatch);

  @override
  CalendarTriggerConfig hasVideoLink(bool? hasVideoLink) =>
      call(hasVideoLink: hasVideoLink);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CalendarTriggerConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CalendarTriggerConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CalendarTriggerConfig call({
    Object? integrationId = const $CopyWithPlaceholder(),
    Object? offsetMinutes = const $CopyWithPlaceholder(),
    Object? calendar = const $CopyWithPlaceholder(),
    Object? outsideGuests = const $CopyWithPlaceholder(),
    Object? titleMatch = const $CopyWithPlaceholder(),
    Object? hasVideoLink = const $CopyWithPlaceholder(),
  }) {
    return CalendarTriggerConfig(
      integrationId:
          integrationId == const $CopyWithPlaceholder() || integrationId == null
          ? _value.integrationId
          // ignore: cast_nullable_to_non_nullable
          : integrationId as String,
      offsetMinutes:
          offsetMinutes == const $CopyWithPlaceholder() || offsetMinutes == null
          ? _value.offsetMinutes
          // ignore: cast_nullable_to_non_nullable
          : offsetMinutes as int,
      calendar: calendar == const $CopyWithPlaceholder()
          ? _value.calendar
          // ignore: cast_nullable_to_non_nullable
          : calendar as String?,
      outsideGuests: outsideGuests == const $CopyWithPlaceholder()
          ? _value.outsideGuests
          // ignore: cast_nullable_to_non_nullable
          : outsideGuests as bool?,
      titleMatch: titleMatch == const $CopyWithPlaceholder()
          ? _value.titleMatch
          // ignore: cast_nullable_to_non_nullable
          : titleMatch as String?,
      hasVideoLink: hasVideoLink == const $CopyWithPlaceholder()
          ? _value.hasVideoLink
          // ignore: cast_nullable_to_non_nullable
          : hasVideoLink as bool?,
    );
  }
}

extension $CalendarTriggerConfigCopyWith on CalendarTriggerConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCalendarTriggerConfig.copyWith(...)` or `instanceOfCalendarTriggerConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CalendarTriggerConfigCWProxy get copyWith =>
      _$CalendarTriggerConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalendarTriggerConfig _$CalendarTriggerConfigFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CalendarTriggerConfig',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['integration_id', 'offset_minutes']);
    final val = CalendarTriggerConfig(
      integrationId: $checkedConvert('integration_id', (v) => v as String),
      offsetMinutes: $checkedConvert(
        'offset_minutes',
        (v) => (v as num).toInt(),
      ),
      calendar: $checkedConvert('calendar', (v) => v as String?),
      outsideGuests: $checkedConvert('outside_guests', (v) => v as bool?),
      titleMatch: $checkedConvert('title_match', (v) => v as String?),
      hasVideoLink: $checkedConvert('has_video_link', (v) => v as bool?),
    );
    return val;
  },
  fieldKeyMap: const {
    'integrationId': 'integration_id',
    'offsetMinutes': 'offset_minutes',
    'outsideGuests': 'outside_guests',
    'titleMatch': 'title_match',
    'hasVideoLink': 'has_video_link',
  },
);

Map<String, dynamic> _$CalendarTriggerConfigToJson(
  CalendarTriggerConfig instance,
) => <String, dynamic>{
  'integration_id': instance.integrationId,
  'offset_minutes': instance.offsetMinutes,
  'calendar': ?instance.calendar,
  'outside_guests': ?instance.outsideGuests,
  'title_match': ?instance.titleMatch,
  'has_video_link': ?instance.hasVideoLink,
};

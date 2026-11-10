// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_reading.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeviceReadingCWProxy {
  DeviceReading id(String id);

  DeviceReading sourceId(String sourceId);

  DeviceReading kind(DeviceKind kind);

  DeviceReading periodStart(DateTime periodStart);

  DeviceReading periodEnd(DateTime periodEnd);

  DeviceReading externalId(String externalId);

  DeviceReading summary(Map<String, Object?> summary);

  DeviceReading collectedAt(DateTime collectedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceReading(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceReading(...).copyWith(id: 12, name: "My name")
  /// ```
  DeviceReading call({
    String id,
    String sourceId,
    DeviceKind kind,
    DateTime periodStart,
    DateTime periodEnd,
    String externalId,
    Map<String, Object?> summary,
    DateTime collectedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeviceReading.copyWith(...)` or call `instanceOfDeviceReading.copyWith.fieldName(value)` for a single field.
class _$DeviceReadingCWProxyImpl implements _$DeviceReadingCWProxy {
  const _$DeviceReadingCWProxyImpl(this._value);

  final DeviceReading _value;

  @override
  DeviceReading id(String id) => call(id: id);

  @override
  DeviceReading sourceId(String sourceId) => call(sourceId: sourceId);

  @override
  DeviceReading kind(DeviceKind kind) => call(kind: kind);

  @override
  DeviceReading periodStart(DateTime periodStart) =>
      call(periodStart: periodStart);

  @override
  DeviceReading periodEnd(DateTime periodEnd) => call(periodEnd: periodEnd);

  @override
  DeviceReading externalId(String externalId) => call(externalId: externalId);

  @override
  DeviceReading summary(Map<String, Object?> summary) => call(summary: summary);

  @override
  DeviceReading collectedAt(DateTime collectedAt) =>
      call(collectedAt: collectedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceReading(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceReading(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeviceReading call({
    Object? id = const $CopyWithPlaceholder(),
    Object? sourceId = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? periodStart = const $CopyWithPlaceholder(),
    Object? periodEnd = const $CopyWithPlaceholder(),
    Object? externalId = const $CopyWithPlaceholder(),
    Object? summary = const $CopyWithPlaceholder(),
    Object? collectedAt = const $CopyWithPlaceholder(),
  }) {
    return DeviceReading(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      sourceId: sourceId == const $CopyWithPlaceholder() || sourceId == null
          ? _value.sourceId
          // ignore: cast_nullable_to_non_nullable
          : sourceId as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as DeviceKind,
      periodStart:
          periodStart == const $CopyWithPlaceholder() || periodStart == null
          ? _value.periodStart
          // ignore: cast_nullable_to_non_nullable
          : periodStart as DateTime,
      periodEnd: periodEnd == const $CopyWithPlaceholder() || periodEnd == null
          ? _value.periodEnd
          // ignore: cast_nullable_to_non_nullable
          : periodEnd as DateTime,
      externalId:
          externalId == const $CopyWithPlaceholder() || externalId == null
          ? _value.externalId
          // ignore: cast_nullable_to_non_nullable
          : externalId as String,
      summary: summary == const $CopyWithPlaceholder() || summary == null
          ? _value.summary
          // ignore: cast_nullable_to_non_nullable
          : summary as Map<String, Object?>,
      collectedAt:
          collectedAt == const $CopyWithPlaceholder() || collectedAt == null
          ? _value.collectedAt
          // ignore: cast_nullable_to_non_nullable
          : collectedAt as DateTime,
    );
  }
}

extension $DeviceReadingCopyWith on DeviceReading {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeviceReading.copyWith(...)` or `instanceOfDeviceReading.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeviceReadingCWProxy get copyWith => _$DeviceReadingCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceReading _$DeviceReadingFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DeviceReading',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'source_id',
            'kind',
            'period_start',
            'period_end',
            'external_id',
            'summary',
            'collected_at',
          ],
        );
        final val = DeviceReading(
          id: $checkedConvert('id', (v) => v as String),
          sourceId: $checkedConvert('source_id', (v) => v as String),
          kind: $checkedConvert(
            'kind',
            (v) => $enumDecode(_$DeviceKindEnumMap, v),
          ),
          periodStart: $checkedConvert(
            'period_start',
            (v) => DateTime.parse(v as String),
          ),
          periodEnd: $checkedConvert(
            'period_end',
            (v) => DateTime.parse(v as String),
          ),
          externalId: $checkedConvert('external_id', (v) => v as String),
          summary: $checkedConvert('summary', (v) => v as Map<String, dynamic>),
          collectedAt: $checkedConvert(
            'collected_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'sourceId': 'source_id',
        'periodStart': 'period_start',
        'periodEnd': 'period_end',
        'externalId': 'external_id',
        'collectedAt': 'collected_at',
      },
    );

Map<String, dynamic> _$DeviceReadingToJson(DeviceReading instance) =>
    <String, dynamic>{
      'id': instance.id,
      'source_id': instance.sourceId,
      'kind': _$DeviceKindEnumMap[instance.kind]!,
      'period_start': instance.periodStart.toIso8601String(),
      'period_end': instance.periodEnd.toIso8601String(),
      'external_id': instance.externalId,
      'summary': instance.summary,
      'collected_at': instance.collectedAt.toIso8601String(),
    };

const _$DeviceKindEnumMap = {
  DeviceKind.calendar: 'calendar',
  DeviceKind.reminders: 'reminders',
  DeviceKind.contacts: 'contacts',
  DeviceKind.places: 'places',
  DeviceKind.photos: 'photos',
  DeviceKind.health: 'health',
  DeviceKind.notifications: 'notifications',
  DeviceKind.activity: 'activity',
};

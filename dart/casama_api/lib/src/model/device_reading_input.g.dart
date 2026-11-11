// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_reading_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeviceReadingInputCWProxy {
  DeviceReadingInput kind(DeviceKind kind);

  DeviceReadingInput periodStart(DateTime periodStart);

  DeviceReadingInput periodEnd(DateTime periodEnd);

  DeviceReadingInput externalId(String externalId);

  DeviceReadingInput summary(Map<String, Object?> summary);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceReadingInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceReadingInput(...).copyWith(id: 12, name: "My name")
  /// ```
  DeviceReadingInput call({
    DeviceKind kind,
    DateTime periodStart,
    DateTime periodEnd,
    String externalId,
    Map<String, Object?> summary,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeviceReadingInput.copyWith(...)` or call `instanceOfDeviceReadingInput.copyWith.fieldName(value)` for a single field.
class _$DeviceReadingInputCWProxyImpl implements _$DeviceReadingInputCWProxy {
  const _$DeviceReadingInputCWProxyImpl(this._value);

  final DeviceReadingInput _value;

  @override
  DeviceReadingInput kind(DeviceKind kind) => call(kind: kind);

  @override
  DeviceReadingInput periodStart(DateTime periodStart) =>
      call(periodStart: periodStart);

  @override
  DeviceReadingInput periodEnd(DateTime periodEnd) =>
      call(periodEnd: periodEnd);

  @override
  DeviceReadingInput externalId(String externalId) =>
      call(externalId: externalId);

  @override
  DeviceReadingInput summary(Map<String, Object?> summary) =>
      call(summary: summary);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceReadingInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceReadingInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeviceReadingInput call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? periodStart = const $CopyWithPlaceholder(),
    Object? periodEnd = const $CopyWithPlaceholder(),
    Object? externalId = const $CopyWithPlaceholder(),
    Object? summary = const $CopyWithPlaceholder(),
  }) {
    return DeviceReadingInput(
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
    );
  }
}

extension $DeviceReadingInputCopyWith on DeviceReadingInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeviceReadingInput.copyWith(...)` or `instanceOfDeviceReadingInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeviceReadingInputCWProxy get copyWith =>
      _$DeviceReadingInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceReadingInput _$DeviceReadingInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DeviceReadingInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'kind',
            'period_start',
            'period_end',
            'external_id',
            'summary',
          ],
        );
        final val = DeviceReadingInput(
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
        );
        return val;
      },
      fieldKeyMap: const {
        'periodStart': 'period_start',
        'periodEnd': 'period_end',
        'externalId': 'external_id',
      },
    );

Map<String, dynamic> _$DeviceReadingInputToJson(DeviceReadingInput instance) =>
    <String, dynamic>{
      'kind': _$DeviceKindEnumMap[instance.kind]!,
      'period_start': instance.periodStart.toIso8601String(),
      'period_end': instance.periodEnd.toIso8601String(),
      'external_id': instance.externalId,
      'summary': instance.summary,
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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_capacity_alerts_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ServerCapacityAlertsInnerCWProxy {
  ServerCapacityAlertsInner kind(ServerCapacityAlertsInnerKindEnum kind);

  ServerCapacityAlertsInner day(String day);

  ServerCapacityAlertsInner body(String body);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ServerCapacityAlertsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServerCapacityAlertsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  ServerCapacityAlertsInner call({
    ServerCapacityAlertsInnerKindEnum kind,
    String day,
    String body,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfServerCapacityAlertsInner.copyWith(...)` or call `instanceOfServerCapacityAlertsInner.copyWith.fieldName(value)` for a single field.
class _$ServerCapacityAlertsInnerCWProxyImpl
    implements _$ServerCapacityAlertsInnerCWProxy {
  const _$ServerCapacityAlertsInnerCWProxyImpl(this._value);

  final ServerCapacityAlertsInner _value;

  @override
  ServerCapacityAlertsInner kind(ServerCapacityAlertsInnerKindEnum kind) =>
      call(kind: kind);

  @override
  ServerCapacityAlertsInner day(String day) => call(day: day);

  @override
  ServerCapacityAlertsInner body(String body) => call(body: body);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ServerCapacityAlertsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServerCapacityAlertsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ServerCapacityAlertsInner call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? day = const $CopyWithPlaceholder(),
    Object? body = const $CopyWithPlaceholder(),
  }) {
    return ServerCapacityAlertsInner(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as ServerCapacityAlertsInnerKindEnum,
      day: day == const $CopyWithPlaceholder() || day == null
          ? _value.day
          // ignore: cast_nullable_to_non_nullable
          : day as String,
      body: body == const $CopyWithPlaceholder() || body == null
          ? _value.body
          // ignore: cast_nullable_to_non_nullable
          : body as String,
    );
  }
}

extension $ServerCapacityAlertsInnerCopyWith on ServerCapacityAlertsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfServerCapacityAlertsInner.copyWith(...)` or `instanceOfServerCapacityAlertsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ServerCapacityAlertsInnerCWProxy get copyWith =>
      _$ServerCapacityAlertsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServerCapacityAlertsInner _$ServerCapacityAlertsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ServerCapacityAlertsInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['kind', 'day', 'body']);
  final val = ServerCapacityAlertsInner(
    kind: $checkedConvert(
      'kind',
      (v) => $enumDecode(_$ServerCapacityAlertsInnerKindEnumEnumMap, v),
    ),
    day: $checkedConvert('day', (v) => v as String),
    body: $checkedConvert('body', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$ServerCapacityAlertsInnerToJson(
  ServerCapacityAlertsInner instance,
) => <String, dynamic>{
  'kind': _$ServerCapacityAlertsInnerKindEnumEnumMap[instance.kind]!,
  'day': instance.day,
  'body': instance.body,
};

const _$ServerCapacityAlertsInnerKindEnumEnumMap = {
  ServerCapacityAlertsInnerKindEnum.earlyWarning: 'early_warning',
  ServerCapacityAlertsInnerKindEnum.capacityFull: 'capacity_full',
  ServerCapacityAlertsInnerKindEnum.lowMemory: 'low_memory',
  ServerCapacityAlertsInnerKindEnum.disk: 'disk',
};

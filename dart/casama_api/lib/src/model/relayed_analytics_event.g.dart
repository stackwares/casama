// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relayed_analytics_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RelayedAnalyticsEventCWProxy {
  RelayedAnalyticsEvent name(String name);

  RelayedAnalyticsEvent properties(Map<String, Object?>? properties);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RelayedAnalyticsEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RelayedAnalyticsEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  RelayedAnalyticsEvent call({String name, Map<String, Object?>? properties});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRelayedAnalyticsEvent.copyWith(...)` or call `instanceOfRelayedAnalyticsEvent.copyWith.fieldName(value)` for a single field.
class _$RelayedAnalyticsEventCWProxyImpl
    implements _$RelayedAnalyticsEventCWProxy {
  const _$RelayedAnalyticsEventCWProxyImpl(this._value);

  final RelayedAnalyticsEvent _value;

  @override
  RelayedAnalyticsEvent name(String name) => call(name: name);

  @override
  RelayedAnalyticsEvent properties(Map<String, Object?>? properties) =>
      call(properties: properties);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RelayedAnalyticsEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RelayedAnalyticsEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RelayedAnalyticsEvent call({
    Object? name = const $CopyWithPlaceholder(),
    Object? properties = const $CopyWithPlaceholder(),
  }) {
    return RelayedAnalyticsEvent(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      properties: properties == const $CopyWithPlaceholder()
          ? _value.properties
          // ignore: cast_nullable_to_non_nullable
          : properties as Map<String, Object?>?,
    );
  }
}

extension $RelayedAnalyticsEventCopyWith on RelayedAnalyticsEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRelayedAnalyticsEvent.copyWith(...)` or `instanceOfRelayedAnalyticsEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RelayedAnalyticsEventCWProxy get copyWith =>
      _$RelayedAnalyticsEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RelayedAnalyticsEvent _$RelayedAnalyticsEventFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RelayedAnalyticsEvent', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name']);
  final val = RelayedAnalyticsEvent(
    name: $checkedConvert('name', (v) => v as String),
    properties: $checkedConvert(
      'properties',
      (v) => v as Map<String, dynamic>?,
    ),
  );
  return val;
});

Map<String, dynamic> _$RelayedAnalyticsEventToJson(
  RelayedAnalyticsEvent instance,
) => <String, dynamic>{
  'name': instance.name,
  'properties': ?instance.properties,
};

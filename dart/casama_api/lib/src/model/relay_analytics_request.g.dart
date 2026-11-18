// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relay_analytics_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RelayAnalyticsRequestCWProxy {
  RelayAnalyticsRequest platform(RelayAnalyticsRequestPlatformEnum platform);

  RelayAnalyticsRequest events(List<RelayedAnalyticsEvent> events);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RelayAnalyticsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RelayAnalyticsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  RelayAnalyticsRequest call({
    RelayAnalyticsRequestPlatformEnum platform,
    List<RelayedAnalyticsEvent> events,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRelayAnalyticsRequest.copyWith(...)` or call `instanceOfRelayAnalyticsRequest.copyWith.fieldName(value)` for a single field.
class _$RelayAnalyticsRequestCWProxyImpl
    implements _$RelayAnalyticsRequestCWProxy {
  const _$RelayAnalyticsRequestCWProxyImpl(this._value);

  final RelayAnalyticsRequest _value;

  @override
  RelayAnalyticsRequest platform(RelayAnalyticsRequestPlatformEnum platform) =>
      call(platform: platform);

  @override
  RelayAnalyticsRequest events(List<RelayedAnalyticsEvent> events) =>
      call(events: events);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RelayAnalyticsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RelayAnalyticsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RelayAnalyticsRequest call({
    Object? platform = const $CopyWithPlaceholder(),
    Object? events = const $CopyWithPlaceholder(),
  }) {
    return RelayAnalyticsRequest(
      platform: platform == const $CopyWithPlaceholder() || platform == null
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as RelayAnalyticsRequestPlatformEnum,
      events: events == const $CopyWithPlaceholder() || events == null
          ? _value.events
          // ignore: cast_nullable_to_non_nullable
          : events as List<RelayedAnalyticsEvent>,
    );
  }
}

extension $RelayAnalyticsRequestCopyWith on RelayAnalyticsRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRelayAnalyticsRequest.copyWith(...)` or `instanceOfRelayAnalyticsRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RelayAnalyticsRequestCWProxy get copyWith =>
      _$RelayAnalyticsRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RelayAnalyticsRequest _$RelayAnalyticsRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RelayAnalyticsRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['platform', 'events']);
  final val = RelayAnalyticsRequest(
    platform: $checkedConvert(
      'platform',
      (v) => $enumDecode(_$RelayAnalyticsRequestPlatformEnumEnumMap, v),
    ),
    events: $checkedConvert(
      'events',
      (v) => (v as List<dynamic>)
          .map((e) => RelayedAnalyticsEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$RelayAnalyticsRequestToJson(
  RelayAnalyticsRequest instance,
) => <String, dynamic>{
  'platform': _$RelayAnalyticsRequestPlatformEnumEnumMap[instance.platform]!,
  'events': instance.events.map((e) => e.toJson()).toList(),
};

const _$RelayAnalyticsRequestPlatformEnumEnumMap = {
  RelayAnalyticsRequestPlatformEnum.windows: 'windows',
  RelayAnalyticsRequestPlatformEnum.linux: 'linux',
};

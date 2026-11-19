// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_session_limits.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VoiceSessionLimitsCWProxy {
  VoiceSessionLimits silenceSeconds(int silenceSeconds);

  VoiceSessionLimits heartbeatSeconds(int heartbeatSeconds);

  VoiceSessionLimits maxCallSeconds(int maxCallSeconds);

  VoiceSessionLimits warningSeconds(int warningSeconds);

  VoiceSessionLimits appEndsAtMax(bool appEndsAtMax);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceSessionLimits(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceSessionLimits(...).copyWith(id: 12, name: "My name")
  /// ```
  VoiceSessionLimits call({
    int silenceSeconds,
    int heartbeatSeconds,
    int maxCallSeconds,
    int warningSeconds,
    bool appEndsAtMax,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVoiceSessionLimits.copyWith(...)` or call `instanceOfVoiceSessionLimits.copyWith.fieldName(value)` for a single field.
class _$VoiceSessionLimitsCWProxyImpl implements _$VoiceSessionLimitsCWProxy {
  const _$VoiceSessionLimitsCWProxyImpl(this._value);

  final VoiceSessionLimits _value;

  @override
  VoiceSessionLimits silenceSeconds(int silenceSeconds) =>
      call(silenceSeconds: silenceSeconds);

  @override
  VoiceSessionLimits heartbeatSeconds(int heartbeatSeconds) =>
      call(heartbeatSeconds: heartbeatSeconds);

  @override
  VoiceSessionLimits maxCallSeconds(int maxCallSeconds) =>
      call(maxCallSeconds: maxCallSeconds);

  @override
  VoiceSessionLimits warningSeconds(int warningSeconds) =>
      call(warningSeconds: warningSeconds);

  @override
  VoiceSessionLimits appEndsAtMax(bool appEndsAtMax) =>
      call(appEndsAtMax: appEndsAtMax);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceSessionLimits(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceSessionLimits(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VoiceSessionLimits call({
    Object? silenceSeconds = const $CopyWithPlaceholder(),
    Object? heartbeatSeconds = const $CopyWithPlaceholder(),
    Object? maxCallSeconds = const $CopyWithPlaceholder(),
    Object? warningSeconds = const $CopyWithPlaceholder(),
    Object? appEndsAtMax = const $CopyWithPlaceholder(),
  }) {
    return VoiceSessionLimits(
      silenceSeconds:
          silenceSeconds == const $CopyWithPlaceholder() ||
              silenceSeconds == null
          ? _value.silenceSeconds
          // ignore: cast_nullable_to_non_nullable
          : silenceSeconds as int,
      heartbeatSeconds:
          heartbeatSeconds == const $CopyWithPlaceholder() ||
              heartbeatSeconds == null
          ? _value.heartbeatSeconds
          // ignore: cast_nullable_to_non_nullable
          : heartbeatSeconds as int,
      maxCallSeconds:
          maxCallSeconds == const $CopyWithPlaceholder() ||
              maxCallSeconds == null
          ? _value.maxCallSeconds
          // ignore: cast_nullable_to_non_nullable
          : maxCallSeconds as int,
      warningSeconds:
          warningSeconds == const $CopyWithPlaceholder() ||
              warningSeconds == null
          ? _value.warningSeconds
          // ignore: cast_nullable_to_non_nullable
          : warningSeconds as int,
      appEndsAtMax:
          appEndsAtMax == const $CopyWithPlaceholder() || appEndsAtMax == null
          ? _value.appEndsAtMax
          // ignore: cast_nullable_to_non_nullable
          : appEndsAtMax as bool,
    );
  }
}

extension $VoiceSessionLimitsCopyWith on VoiceSessionLimits {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVoiceSessionLimits.copyWith(...)` or `instanceOfVoiceSessionLimits.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VoiceSessionLimitsCWProxy get copyWith =>
      _$VoiceSessionLimitsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceSessionLimits _$VoiceSessionLimitsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'VoiceSessionLimits',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'silence_seconds',
            'heartbeat_seconds',
            'max_call_seconds',
            'warning_seconds',
            'app_ends_at_max',
          ],
        );
        final val = VoiceSessionLimits(
          silenceSeconds: $checkedConvert(
            'silence_seconds',
            (v) => (v as num).toInt(),
          ),
          heartbeatSeconds: $checkedConvert(
            'heartbeat_seconds',
            (v) => (v as num).toInt(),
          ),
          maxCallSeconds: $checkedConvert(
            'max_call_seconds',
            (v) => (v as num).toInt(),
          ),
          warningSeconds: $checkedConvert(
            'warning_seconds',
            (v) => (v as num).toInt(),
          ),
          appEndsAtMax: $checkedConvert('app_ends_at_max', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'silenceSeconds': 'silence_seconds',
        'heartbeatSeconds': 'heartbeat_seconds',
        'maxCallSeconds': 'max_call_seconds',
        'warningSeconds': 'warning_seconds',
        'appEndsAtMax': 'app_ends_at_max',
      },
    );

Map<String, dynamic> _$VoiceSessionLimitsToJson(VoiceSessionLimits instance) =>
    <String, dynamic>{
      'silence_seconds': instance.silenceSeconds,
      'heartbeat_seconds': instance.heartbeatSeconds,
      'max_call_seconds': instance.maxCallSeconds,
      'warning_seconds': instance.warningSeconds,
      'app_ends_at_max': instance.appEndsAtMax,
    };

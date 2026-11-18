// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_heartbeat.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VoiceHeartbeatCWProxy {
  VoiceHeartbeat ended(bool ended);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceHeartbeat(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceHeartbeat(...).copyWith(id: 12, name: "My name")
  /// ```
  VoiceHeartbeat call({bool ended});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVoiceHeartbeat.copyWith(...)` or call `instanceOfVoiceHeartbeat.copyWith.fieldName(value)` for a single field.
class _$VoiceHeartbeatCWProxyImpl implements _$VoiceHeartbeatCWProxy {
  const _$VoiceHeartbeatCWProxyImpl(this._value);

  final VoiceHeartbeat _value;

  @override
  VoiceHeartbeat ended(bool ended) => call(ended: ended);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceHeartbeat(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceHeartbeat(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VoiceHeartbeat call({Object? ended = const $CopyWithPlaceholder()}) {
    return VoiceHeartbeat(
      ended: ended == const $CopyWithPlaceholder() || ended == null
          ? _value.ended
          // ignore: cast_nullable_to_non_nullable
          : ended as bool,
    );
  }
}

extension $VoiceHeartbeatCopyWith on VoiceHeartbeat {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVoiceHeartbeat.copyWith(...)` or `instanceOfVoiceHeartbeat.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VoiceHeartbeatCWProxy get copyWith => _$VoiceHeartbeatCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceHeartbeat _$VoiceHeartbeatFromJson(Map<String, dynamic> json) =>
    $checkedCreate('VoiceHeartbeat', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['ended']);
      final val = VoiceHeartbeat(
        ended: $checkedConvert('ended', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$VoiceHeartbeatToJson(VoiceHeartbeat instance) =>
    <String, dynamic>{'ended': instance.ended};

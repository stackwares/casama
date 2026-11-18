// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_heartbeat_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VoiceHeartbeatRequestCWProxy {
  VoiceHeartbeatRequest usage(VoiceHeartbeatRequestUsage? usage);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceHeartbeatRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceHeartbeatRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  VoiceHeartbeatRequest call({VoiceHeartbeatRequestUsage? usage});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVoiceHeartbeatRequest.copyWith(...)` or call `instanceOfVoiceHeartbeatRequest.copyWith.fieldName(value)` for a single field.
class _$VoiceHeartbeatRequestCWProxyImpl
    implements _$VoiceHeartbeatRequestCWProxy {
  const _$VoiceHeartbeatRequestCWProxyImpl(this._value);

  final VoiceHeartbeatRequest _value;

  @override
  VoiceHeartbeatRequest usage(VoiceHeartbeatRequestUsage? usage) =>
      call(usage: usage);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceHeartbeatRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceHeartbeatRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VoiceHeartbeatRequest call({Object? usage = const $CopyWithPlaceholder()}) {
    return VoiceHeartbeatRequest(
      usage: usage == const $CopyWithPlaceholder()
          ? _value.usage
          // ignore: cast_nullable_to_non_nullable
          : usage as VoiceHeartbeatRequestUsage?,
    );
  }
}

extension $VoiceHeartbeatRequestCopyWith on VoiceHeartbeatRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVoiceHeartbeatRequest.copyWith(...)` or `instanceOfVoiceHeartbeatRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VoiceHeartbeatRequestCWProxy get copyWith =>
      _$VoiceHeartbeatRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceHeartbeatRequest _$VoiceHeartbeatRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('VoiceHeartbeatRequest', json, ($checkedConvert) {
  final val = VoiceHeartbeatRequest(
    usage: $checkedConvert(
      'usage',
      (v) => v == null
          ? null
          : VoiceHeartbeatRequestUsage.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$VoiceHeartbeatRequestToJson(
  VoiceHeartbeatRequest instance,
) => <String, dynamic>{'usage': ?instance.usage?.toJson()};

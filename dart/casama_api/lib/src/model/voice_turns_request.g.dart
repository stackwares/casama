// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_turns_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VoiceTurnsRequestCWProxy {
  VoiceTurnsRequest liveCallId(String liveCallId);

  VoiceTurnsRequest turns(List<VoiceTurnsRequestTurnsInner> turns);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceTurnsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceTurnsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  VoiceTurnsRequest call({
    String liveCallId,
    List<VoiceTurnsRequestTurnsInner> turns,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVoiceTurnsRequest.copyWith(...)` or call `instanceOfVoiceTurnsRequest.copyWith.fieldName(value)` for a single field.
class _$VoiceTurnsRequestCWProxyImpl implements _$VoiceTurnsRequestCWProxy {
  const _$VoiceTurnsRequestCWProxyImpl(this._value);

  final VoiceTurnsRequest _value;

  @override
  VoiceTurnsRequest liveCallId(String liveCallId) =>
      call(liveCallId: liveCallId);

  @override
  VoiceTurnsRequest turns(List<VoiceTurnsRequestTurnsInner> turns) =>
      call(turns: turns);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceTurnsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceTurnsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VoiceTurnsRequest call({
    Object? liveCallId = const $CopyWithPlaceholder(),
    Object? turns = const $CopyWithPlaceholder(),
  }) {
    return VoiceTurnsRequest(
      liveCallId:
          liveCallId == const $CopyWithPlaceholder() || liveCallId == null
          ? _value.liveCallId
          // ignore: cast_nullable_to_non_nullable
          : liveCallId as String,
      turns: turns == const $CopyWithPlaceholder() || turns == null
          ? _value.turns
          // ignore: cast_nullable_to_non_nullable
          : turns as List<VoiceTurnsRequestTurnsInner>,
    );
  }
}

extension $VoiceTurnsRequestCopyWith on VoiceTurnsRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVoiceTurnsRequest.copyWith(...)` or `instanceOfVoiceTurnsRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VoiceTurnsRequestCWProxy get copyWith =>
      _$VoiceTurnsRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceTurnsRequest _$VoiceTurnsRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('VoiceTurnsRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['live_call_id', 'turns']);
      final val = VoiceTurnsRequest(
        liveCallId: $checkedConvert('live_call_id', (v) => v as String),
        turns: $checkedConvert(
          'turns',
          (v) => (v as List<dynamic>)
              .map(
                (e) => VoiceTurnsRequestTurnsInner.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'liveCallId': 'live_call_id'});

Map<String, dynamic> _$VoiceTurnsRequestToJson(VoiceTurnsRequest instance) =>
    <String, dynamic>{
      'live_call_id': instance.liveCallId,
      'turns': instance.turns.map((e) => e.toJson()).toList(),
    };

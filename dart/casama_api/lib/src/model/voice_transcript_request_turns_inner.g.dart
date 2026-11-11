// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_transcript_request_turns_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VoiceTranscriptRequestTurnsInnerCWProxy {
  VoiceTranscriptRequestTurnsInner role(
    VoiceTranscriptRequestTurnsInnerRoleEnum role,
  );

  VoiceTranscriptRequestTurnsInner text(String text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceTranscriptRequestTurnsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceTranscriptRequestTurnsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  VoiceTranscriptRequestTurnsInner call({
    VoiceTranscriptRequestTurnsInnerRoleEnum role,
    String text,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVoiceTranscriptRequestTurnsInner.copyWith(...)` or call `instanceOfVoiceTranscriptRequestTurnsInner.copyWith.fieldName(value)` for a single field.
class _$VoiceTranscriptRequestTurnsInnerCWProxyImpl
    implements _$VoiceTranscriptRequestTurnsInnerCWProxy {
  const _$VoiceTranscriptRequestTurnsInnerCWProxyImpl(this._value);

  final VoiceTranscriptRequestTurnsInner _value;

  @override
  VoiceTranscriptRequestTurnsInner role(
    VoiceTranscriptRequestTurnsInnerRoleEnum role,
  ) => call(role: role);

  @override
  VoiceTranscriptRequestTurnsInner text(String text) => call(text: text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceTranscriptRequestTurnsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceTranscriptRequestTurnsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VoiceTranscriptRequestTurnsInner call({
    Object? role = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return VoiceTranscriptRequestTurnsInner(
      role: role == const $CopyWithPlaceholder() || role == null
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as VoiceTranscriptRequestTurnsInnerRoleEnum,
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $VoiceTranscriptRequestTurnsInnerCopyWith
    on VoiceTranscriptRequestTurnsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVoiceTranscriptRequestTurnsInner.copyWith(...)` or `instanceOfVoiceTranscriptRequestTurnsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VoiceTranscriptRequestTurnsInnerCWProxy get copyWith =>
      _$VoiceTranscriptRequestTurnsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceTranscriptRequestTurnsInner _$VoiceTranscriptRequestTurnsInnerFromJson(
  Map<String, dynamic> json,
) =>
    $checkedCreate('VoiceTranscriptRequestTurnsInner', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['role', 'text']);
      final val = VoiceTranscriptRequestTurnsInner(
        role: $checkedConvert(
          'role',
          (v) =>
              $enumDecode(_$VoiceTranscriptRequestTurnsInnerRoleEnumEnumMap, v),
        ),
        text: $checkedConvert('text', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$VoiceTranscriptRequestTurnsInnerToJson(
  VoiceTranscriptRequestTurnsInner instance,
) => <String, dynamic>{
  'role': _$VoiceTranscriptRequestTurnsInnerRoleEnumEnumMap[instance.role]!,
  'text': instance.text,
};

const _$VoiceTranscriptRequestTurnsInnerRoleEnumEnumMap = {
  VoiceTranscriptRequestTurnsInnerRoleEnum.user: 'user',
  VoiceTranscriptRequestTurnsInnerRoleEnum.assistant: 'assistant',
};

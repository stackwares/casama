// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_turns_request_turns_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VoiceTurnsRequestTurnsInnerCWProxy {
  VoiceTurnsRequestTurnsInner id(String id);

  VoiceTurnsRequestTurnsInner role(VoiceTurnsRequestTurnsInnerRoleEnum role);

  VoiceTurnsRequestTurnsInner text(String text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceTurnsRequestTurnsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceTurnsRequestTurnsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  VoiceTurnsRequestTurnsInner call({
    String id,
    VoiceTurnsRequestTurnsInnerRoleEnum role,
    String text,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVoiceTurnsRequestTurnsInner.copyWith(...)` or call `instanceOfVoiceTurnsRequestTurnsInner.copyWith.fieldName(value)` for a single field.
class _$VoiceTurnsRequestTurnsInnerCWProxyImpl
    implements _$VoiceTurnsRequestTurnsInnerCWProxy {
  const _$VoiceTurnsRequestTurnsInnerCWProxyImpl(this._value);

  final VoiceTurnsRequestTurnsInner _value;

  @override
  VoiceTurnsRequestTurnsInner id(String id) => call(id: id);

  @override
  VoiceTurnsRequestTurnsInner role(VoiceTurnsRequestTurnsInnerRoleEnum role) =>
      call(role: role);

  @override
  VoiceTurnsRequestTurnsInner text(String text) => call(text: text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceTurnsRequestTurnsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceTurnsRequestTurnsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VoiceTurnsRequestTurnsInner call({
    Object? id = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return VoiceTurnsRequestTurnsInner(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      role: role == const $CopyWithPlaceholder() || role == null
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as VoiceTurnsRequestTurnsInnerRoleEnum,
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $VoiceTurnsRequestTurnsInnerCopyWith on VoiceTurnsRequestTurnsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVoiceTurnsRequestTurnsInner.copyWith(...)` or `instanceOfVoiceTurnsRequestTurnsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VoiceTurnsRequestTurnsInnerCWProxy get copyWith =>
      _$VoiceTurnsRequestTurnsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceTurnsRequestTurnsInner _$VoiceTurnsRequestTurnsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('VoiceTurnsRequestTurnsInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['id', 'role', 'text']);
  final val = VoiceTurnsRequestTurnsInner(
    id: $checkedConvert('id', (v) => v as String),
    role: $checkedConvert(
      'role',
      (v) => $enumDecode(_$VoiceTurnsRequestTurnsInnerRoleEnumEnumMap, v),
    ),
    text: $checkedConvert('text', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$VoiceTurnsRequestTurnsInnerToJson(
  VoiceTurnsRequestTurnsInner instance,
) => <String, dynamic>{
  'id': instance.id,
  'role': _$VoiceTurnsRequestTurnsInnerRoleEnumEnumMap[instance.role]!,
  'text': instance.text,
};

const _$VoiceTurnsRequestTurnsInnerRoleEnumEnumMap = {
  VoiceTurnsRequestTurnsInnerRoleEnum.user: 'user',
  VoiceTurnsRequestTurnsInnerRoleEnum.assistant: 'assistant',
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_loaded_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SkillLoadedEventPayloadCWProxy {
  SkillLoadedEventPayload skillId(String skillId);

  SkillLoadedEventPayload name(String name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SkillLoadedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SkillLoadedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  SkillLoadedEventPayload call({String skillId, String name});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSkillLoadedEventPayload.copyWith(...)` or call `instanceOfSkillLoadedEventPayload.copyWith.fieldName(value)` for a single field.
class _$SkillLoadedEventPayloadCWProxyImpl
    implements _$SkillLoadedEventPayloadCWProxy {
  const _$SkillLoadedEventPayloadCWProxyImpl(this._value);

  final SkillLoadedEventPayload _value;

  @override
  SkillLoadedEventPayload skillId(String skillId) => call(skillId: skillId);

  @override
  SkillLoadedEventPayload name(String name) => call(name: name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SkillLoadedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SkillLoadedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SkillLoadedEventPayload call({
    Object? skillId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return SkillLoadedEventPayload(
      skillId: skillId == const $CopyWithPlaceholder() || skillId == null
          ? _value.skillId
          // ignore: cast_nullable_to_non_nullable
          : skillId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $SkillLoadedEventPayloadCopyWith on SkillLoadedEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSkillLoadedEventPayload.copyWith(...)` or `instanceOfSkillLoadedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SkillLoadedEventPayloadCWProxy get copyWith =>
      _$SkillLoadedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkillLoadedEventPayload _$SkillLoadedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SkillLoadedEventPayload', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['skill_id', 'name']);
  final val = SkillLoadedEventPayload(
    skillId: $checkedConvert('skill_id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'skillId': 'skill_id'});

Map<String, dynamic> _$SkillLoadedEventPayloadToJson(
  SkillLoadedEventPayload instance,
) => <String, dynamic>{'skill_id': instance.skillId, 'name': instance.name};

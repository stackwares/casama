// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_loaded_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SkillLoadedEventPayloadCWProxy {
  SkillLoadedEventPayload skillId(String skillId);

  SkillLoadedEventPayload name(String name);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SkillLoadedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SkillLoadedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  SkillLoadedEventPayload call({String skillId, String name});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSkillLoadedEventPayload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSkillLoadedEventPayload.copyWith.fieldName(...)`
class _$SkillLoadedEventPayloadCWProxyImpl
    implements _$SkillLoadedEventPayloadCWProxy {
  const _$SkillLoadedEventPayloadCWProxyImpl(this._value);

  final SkillLoadedEventPayload _value;

  @override
  SkillLoadedEventPayload skillId(String skillId) => this(skillId: skillId);

  @override
  SkillLoadedEventPayload name(String name) => this(name: name);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SkillLoadedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SkillLoadedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  SkillLoadedEventPayload call({
    Object? skillId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return SkillLoadedEventPayload(
      skillId: skillId == const $CopyWithPlaceholder()
          ? _value.skillId
          // ignore: cast_nullable_to_non_nullable
          : skillId as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $SkillLoadedEventPayloadCopyWith on SkillLoadedEventPayload {
  /// Returns a callable class that can be used as follows: `instanceOfSkillLoadedEventPayload.copyWith(...)` or like so:`instanceOfSkillLoadedEventPayload.copyWith.fieldName(...)`.
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

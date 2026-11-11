// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_skills_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PluginSkillsInnerCWProxy {
  PluginSkillsInner id(String id);

  PluginSkillsInner name(String name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginSkillsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginSkillsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  PluginSkillsInner call({String id, String name});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPluginSkillsInner.copyWith(...)` or call `instanceOfPluginSkillsInner.copyWith.fieldName(value)` for a single field.
class _$PluginSkillsInnerCWProxyImpl implements _$PluginSkillsInnerCWProxy {
  const _$PluginSkillsInnerCWProxyImpl(this._value);

  final PluginSkillsInner _value;

  @override
  PluginSkillsInner id(String id) => call(id: id);

  @override
  PluginSkillsInner name(String name) => call(name: name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginSkillsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginSkillsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PluginSkillsInner call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return PluginSkillsInner(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $PluginSkillsInnerCopyWith on PluginSkillsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPluginSkillsInner.copyWith(...)` or `instanceOfPluginSkillsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PluginSkillsInnerCWProxy get copyWith =>
      _$PluginSkillsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PluginSkillsInner _$PluginSkillsInnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PluginSkillsInner', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'name']);
      final val = PluginSkillsInner(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PluginSkillsInnerToJson(PluginSkillsInner instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_preview_skills_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PluginPreviewSkillsInnerCWProxy {
  PluginPreviewSkillsInner name(String name);

  PluginPreviewSkillsInner description(String description);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginPreviewSkillsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginPreviewSkillsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  PluginPreviewSkillsInner call({String name, String description});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPluginPreviewSkillsInner.copyWith(...)` or call `instanceOfPluginPreviewSkillsInner.copyWith.fieldName(value)` for a single field.
class _$PluginPreviewSkillsInnerCWProxyImpl
    implements _$PluginPreviewSkillsInnerCWProxy {
  const _$PluginPreviewSkillsInnerCWProxyImpl(this._value);

  final PluginPreviewSkillsInner _value;

  @override
  PluginPreviewSkillsInner name(String name) => call(name: name);

  @override
  PluginPreviewSkillsInner description(String description) =>
      call(description: description);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginPreviewSkillsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginPreviewSkillsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PluginPreviewSkillsInner call({
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
  }) {
    return PluginPreviewSkillsInner(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
    );
  }
}

extension $PluginPreviewSkillsInnerCopyWith on PluginPreviewSkillsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPluginPreviewSkillsInner.copyWith(...)` or `instanceOfPluginPreviewSkillsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PluginPreviewSkillsInnerCWProxy get copyWith =>
      _$PluginPreviewSkillsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PluginPreviewSkillsInner _$PluginPreviewSkillsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PluginPreviewSkillsInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name', 'description']);
  final val = PluginPreviewSkillsInner(
    name: $checkedConvert('name', (v) => v as String),
    description: $checkedConvert('description', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$PluginPreviewSkillsInnerToJson(
  PluginPreviewSkillsInner instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
};

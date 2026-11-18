// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_skill_preview.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackSkillPreviewCWProxy {
  PackSkillPreview name(String name);

  PackSkillPreview description(String description);

  PackSkillPreview scope(PackSkillPreviewScopeEnum scope);

  PackSkillPreview bots(List<String> bots);

  PackSkillPreview runsScripts(bool runsScripts);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackSkillPreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackSkillPreview(...).copyWith(id: 12, name: "My name")
  /// ```
  PackSkillPreview call({
    String name,
    String description,
    PackSkillPreviewScopeEnum scope,
    List<String> bots,
    bool runsScripts,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackSkillPreview.copyWith(...)` or call `instanceOfPackSkillPreview.copyWith.fieldName(value)` for a single field.
class _$PackSkillPreviewCWProxyImpl implements _$PackSkillPreviewCWProxy {
  const _$PackSkillPreviewCWProxyImpl(this._value);

  final PackSkillPreview _value;

  @override
  PackSkillPreview name(String name) => call(name: name);

  @override
  PackSkillPreview description(String description) =>
      call(description: description);

  @override
  PackSkillPreview scope(PackSkillPreviewScopeEnum scope) => call(scope: scope);

  @override
  PackSkillPreview bots(List<String> bots) => call(bots: bots);

  @override
  PackSkillPreview runsScripts(bool runsScripts) =>
      call(runsScripts: runsScripts);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackSkillPreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackSkillPreview(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackSkillPreview call({
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? scope = const $CopyWithPlaceholder(),
    Object? bots = const $CopyWithPlaceholder(),
    Object? runsScripts = const $CopyWithPlaceholder(),
  }) {
    return PackSkillPreview(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      scope: scope == const $CopyWithPlaceholder() || scope == null
          ? _value.scope
          // ignore: cast_nullable_to_non_nullable
          : scope as PackSkillPreviewScopeEnum,
      bots: bots == const $CopyWithPlaceholder() || bots == null
          ? _value.bots
          // ignore: cast_nullable_to_non_nullable
          : bots as List<String>,
      runsScripts:
          runsScripts == const $CopyWithPlaceholder() || runsScripts == null
          ? _value.runsScripts
          // ignore: cast_nullable_to_non_nullable
          : runsScripts as bool,
    );
  }
}

extension $PackSkillPreviewCopyWith on PackSkillPreview {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackSkillPreview.copyWith(...)` or `instanceOfPackSkillPreview.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackSkillPreviewCWProxy get copyWith => _$PackSkillPreviewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackSkillPreview _$PackSkillPreviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PackSkillPreview', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'name',
          'description',
          'scope',
          'bots',
          'runs_scripts',
        ],
      );
      final val = PackSkillPreview(
        name: $checkedConvert('name', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String),
        scope: $checkedConvert(
          'scope',
          (v) => $enumDecode(_$PackSkillPreviewScopeEnumEnumMap, v),
        ),
        bots: $checkedConvert(
          'bots',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        runsScripts: $checkedConvert('runs_scripts', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'runsScripts': 'runs_scripts'});

Map<String, dynamic> _$PackSkillPreviewToJson(PackSkillPreview instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'scope': _$PackSkillPreviewScopeEnumEnumMap[instance.scope]!,
      'bots': instance.bots,
      'runs_scripts': instance.runsScripts,
    };

const _$PackSkillPreviewScopeEnumEnumMap = {
  PackSkillPreviewScopeEnum.workspace: 'workspace',
  PackSkillPreviewScopeEnum.bot: 'bot',
};

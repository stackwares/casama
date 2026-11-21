// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_browser_settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppBrowserSettingsCWProxy {
  AppBrowserSettings stage(AppBrowserSettingsStageEnum stage);

  AppBrowserSettings testers(List<String> testers);

  AppBrowserSettings reasons(AppBrowserSettingsReasons reasons);

  AppBrowserSettings systems(List<String> systems);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppBrowserSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppBrowserSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  AppBrowserSettings call({
    AppBrowserSettingsStageEnum stage,
    List<String> testers,
    AppBrowserSettingsReasons reasons,
    List<String> systems,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAppBrowserSettings.copyWith(...)` or call `instanceOfAppBrowserSettings.copyWith.fieldName(value)` for a single field.
class _$AppBrowserSettingsCWProxyImpl implements _$AppBrowserSettingsCWProxy {
  const _$AppBrowserSettingsCWProxyImpl(this._value);

  final AppBrowserSettings _value;

  @override
  AppBrowserSettings stage(AppBrowserSettingsStageEnum stage) =>
      call(stage: stage);

  @override
  AppBrowserSettings testers(List<String> testers) => call(testers: testers);

  @override
  AppBrowserSettings reasons(AppBrowserSettingsReasons reasons) =>
      call(reasons: reasons);

  @override
  AppBrowserSettings systems(List<String> systems) => call(systems: systems);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppBrowserSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppBrowserSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AppBrowserSettings call({
    Object? stage = const $CopyWithPlaceholder(),
    Object? testers = const $CopyWithPlaceholder(),
    Object? reasons = const $CopyWithPlaceholder(),
    Object? systems = const $CopyWithPlaceholder(),
  }) {
    return AppBrowserSettings(
      stage: stage == const $CopyWithPlaceholder() || stage == null
          ? _value.stage
          // ignore: cast_nullable_to_non_nullable
          : stage as AppBrowserSettingsStageEnum,
      testers: testers == const $CopyWithPlaceholder() || testers == null
          ? _value.testers
          // ignore: cast_nullable_to_non_nullable
          : testers as List<String>,
      reasons: reasons == const $CopyWithPlaceholder() || reasons == null
          ? _value.reasons
          // ignore: cast_nullable_to_non_nullable
          : reasons as AppBrowserSettingsReasons,
      systems: systems == const $CopyWithPlaceholder() || systems == null
          ? _value.systems
          // ignore: cast_nullable_to_non_nullable
          : systems as List<String>,
    );
  }
}

extension $AppBrowserSettingsCopyWith on AppBrowserSettings {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAppBrowserSettings.copyWith(...)` or `instanceOfAppBrowserSettings.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppBrowserSettingsCWProxy get copyWith =>
      _$AppBrowserSettingsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppBrowserSettings _$AppBrowserSettingsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AppBrowserSettings', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['stage', 'testers', 'reasons', 'systems'],
      );
      final val = AppBrowserSettings(
        stage: $checkedConvert(
          'stage',
          (v) => $enumDecode(_$AppBrowserSettingsStageEnumEnumMap, v),
        ),
        testers: $checkedConvert(
          'testers',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        reasons: $checkedConvert(
          'reasons',
          (v) => AppBrowserSettingsReasons.fromJson(v as Map<String, dynamic>),
        ),
        systems: $checkedConvert(
          'systems',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AppBrowserSettingsToJson(AppBrowserSettings instance) =>
    <String, dynamic>{
      'stage': _$AppBrowserSettingsStageEnumEnumMap[instance.stage]!,
      'testers': instance.testers,
      'reasons': instance.reasons.toJson(),
      'systems': instance.systems,
    };

const _$AppBrowserSettingsStageEnumEnumMap = {
  AppBrowserSettingsStageEnum.off: 'off',
  AppBrowserSettingsStageEnum.testers: 'testers',
  AppBrowserSettingsStageEnum.on_: 'on',
};

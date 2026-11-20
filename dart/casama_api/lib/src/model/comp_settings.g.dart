// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comp_settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CompSettingsCWProxy {
  CompSettings enabled(bool enabled);

  CompSettings grantPlans(List<String> grantPlans);

  CompSettings codePlans(List<String> codePlans);

  CompSettings maxMonths(int maxMonths);

  CompSettings maxActive(int maxActive);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CompSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CompSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  CompSettings call({
    bool enabled,
    List<String> grantPlans,
    List<String> codePlans,
    int maxMonths,
    int maxActive,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCompSettings.copyWith(...)` or call `instanceOfCompSettings.copyWith.fieldName(value)` for a single field.
class _$CompSettingsCWProxyImpl implements _$CompSettingsCWProxy {
  const _$CompSettingsCWProxyImpl(this._value);

  final CompSettings _value;

  @override
  CompSettings enabled(bool enabled) => call(enabled: enabled);

  @override
  CompSettings grantPlans(List<String> grantPlans) =>
      call(grantPlans: grantPlans);

  @override
  CompSettings codePlans(List<String> codePlans) => call(codePlans: codePlans);

  @override
  CompSettings maxMonths(int maxMonths) => call(maxMonths: maxMonths);

  @override
  CompSettings maxActive(int maxActive) => call(maxActive: maxActive);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CompSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CompSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CompSettings call({
    Object? enabled = const $CopyWithPlaceholder(),
    Object? grantPlans = const $CopyWithPlaceholder(),
    Object? codePlans = const $CopyWithPlaceholder(),
    Object? maxMonths = const $CopyWithPlaceholder(),
    Object? maxActive = const $CopyWithPlaceholder(),
  }) {
    return CompSettings(
      enabled: enabled == const $CopyWithPlaceholder() || enabled == null
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
      grantPlans:
          grantPlans == const $CopyWithPlaceholder() || grantPlans == null
          ? _value.grantPlans
          // ignore: cast_nullable_to_non_nullable
          : grantPlans as List<String>,
      codePlans: codePlans == const $CopyWithPlaceholder() || codePlans == null
          ? _value.codePlans
          // ignore: cast_nullable_to_non_nullable
          : codePlans as List<String>,
      maxMonths: maxMonths == const $CopyWithPlaceholder() || maxMonths == null
          ? _value.maxMonths
          // ignore: cast_nullable_to_non_nullable
          : maxMonths as int,
      maxActive: maxActive == const $CopyWithPlaceholder() || maxActive == null
          ? _value.maxActive
          // ignore: cast_nullable_to_non_nullable
          : maxActive as int,
    );
  }
}

extension $CompSettingsCopyWith on CompSettings {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCompSettings.copyWith(...)` or `instanceOfCompSettings.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CompSettingsCWProxy get copyWith => _$CompSettingsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompSettings _$CompSettingsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CompSettings',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'enabled',
            'grant_plans',
            'code_plans',
            'max_months',
            'max_active',
          ],
        );
        final val = CompSettings(
          enabled: $checkedConvert('enabled', (v) => v as bool),
          grantPlans: $checkedConvert(
            'grant_plans',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          codePlans: $checkedConvert(
            'code_plans',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          maxMonths: $checkedConvert('max_months', (v) => (v as num).toInt()),
          maxActive: $checkedConvert('max_active', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'grantPlans': 'grant_plans',
        'codePlans': 'code_plans',
        'maxMonths': 'max_months',
        'maxActive': 'max_active',
      },
    );

Map<String, dynamic> _$CompSettingsToJson(CompSettings instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'grant_plans': instance.grantPlans,
      'code_plans': instance.codePlans,
      'max_months': instance.maxMonths,
      'max_active': instance.maxActive,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_pack_summary.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PluginPackSummaryCWProxy {
  PluginPackSummary summary(String summary);

  PluginPackSummary bots(int bots);

  PluginPackSummary routines(int routines);

  PluginPackSummary apps(int apps);

  PluginPackSummary looks(int looks);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginPackSummary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginPackSummary(...).copyWith(id: 12, name: "My name")
  /// ```
  PluginPackSummary call({
    String summary,
    int bots,
    int routines,
    int apps,
    int looks,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPluginPackSummary.copyWith(...)` or call `instanceOfPluginPackSummary.copyWith.fieldName(value)` for a single field.
class _$PluginPackSummaryCWProxyImpl implements _$PluginPackSummaryCWProxy {
  const _$PluginPackSummaryCWProxyImpl(this._value);

  final PluginPackSummary _value;

  @override
  PluginPackSummary summary(String summary) => call(summary: summary);

  @override
  PluginPackSummary bots(int bots) => call(bots: bots);

  @override
  PluginPackSummary routines(int routines) => call(routines: routines);

  @override
  PluginPackSummary apps(int apps) => call(apps: apps);

  @override
  PluginPackSummary looks(int looks) => call(looks: looks);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginPackSummary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginPackSummary(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PluginPackSummary call({
    Object? summary = const $CopyWithPlaceholder(),
    Object? bots = const $CopyWithPlaceholder(),
    Object? routines = const $CopyWithPlaceholder(),
    Object? apps = const $CopyWithPlaceholder(),
    Object? looks = const $CopyWithPlaceholder(),
  }) {
    return PluginPackSummary(
      summary: summary == const $CopyWithPlaceholder() || summary == null
          ? _value.summary
          // ignore: cast_nullable_to_non_nullable
          : summary as String,
      bots: bots == const $CopyWithPlaceholder() || bots == null
          ? _value.bots
          // ignore: cast_nullable_to_non_nullable
          : bots as int,
      routines: routines == const $CopyWithPlaceholder() || routines == null
          ? _value.routines
          // ignore: cast_nullable_to_non_nullable
          : routines as int,
      apps: apps == const $CopyWithPlaceholder() || apps == null
          ? _value.apps
          // ignore: cast_nullable_to_non_nullable
          : apps as int,
      looks: looks == const $CopyWithPlaceholder() || looks == null
          ? _value.looks
          // ignore: cast_nullable_to_non_nullable
          : looks as int,
    );
  }
}

extension $PluginPackSummaryCopyWith on PluginPackSummary {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPluginPackSummary.copyWith(...)` or `instanceOfPluginPackSummary.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PluginPackSummaryCWProxy get copyWith =>
      _$PluginPackSummaryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PluginPackSummary _$PluginPackSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PluginPackSummary', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['summary', 'bots', 'routines', 'apps', 'looks'],
      );
      final val = PluginPackSummary(
        summary: $checkedConvert('summary', (v) => v as String),
        bots: $checkedConvert('bots', (v) => (v as num).toInt()),
        routines: $checkedConvert('routines', (v) => (v as num).toInt()),
        apps: $checkedConvert('apps', (v) => (v as num).toInt()),
        looks: $checkedConvert('looks', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$PluginPackSummaryToJson(PluginPackSummary instance) =>
    <String, dynamic>{
      'summary': instance.summary,
      'bots': instance.bots,
      'routines': instance.routines,
      'apps': instance.apps,
      'looks': instance.looks,
    };

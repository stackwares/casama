// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'browser_guard_sites.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BrowserGuardSitesCWProxy {
  BrowserGuardSites hosts(Map<String, List<String>> hosts);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BrowserGuardSites(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BrowserGuardSites(...).copyWith(id: 12, name: "My name")
  /// ```
  BrowserGuardSites call({Map<String, List<String>> hosts});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBrowserGuardSites.copyWith(...)` or call `instanceOfBrowserGuardSites.copyWith.fieldName(value)` for a single field.
class _$BrowserGuardSitesCWProxyImpl implements _$BrowserGuardSitesCWProxy {
  const _$BrowserGuardSitesCWProxyImpl(this._value);

  final BrowserGuardSites _value;

  @override
  BrowserGuardSites hosts(Map<String, List<String>> hosts) =>
      call(hosts: hosts);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BrowserGuardSites(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BrowserGuardSites(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BrowserGuardSites call({Object? hosts = const $CopyWithPlaceholder()}) {
    return BrowserGuardSites(
      hosts: hosts == const $CopyWithPlaceholder() || hosts == null
          ? _value.hosts
          // ignore: cast_nullable_to_non_nullable
          : hosts as Map<String, List<String>>,
    );
  }
}

extension $BrowserGuardSitesCopyWith on BrowserGuardSites {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBrowserGuardSites.copyWith(...)` or `instanceOfBrowserGuardSites.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BrowserGuardSitesCWProxy get copyWith =>
      _$BrowserGuardSitesCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrowserGuardSites _$BrowserGuardSitesFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BrowserGuardSites', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['hosts']);
      final val = BrowserGuardSites(
        hosts: $checkedConvert(
          'hosts',
          (v) => (v as Map<String, dynamic>).map(
            (k, e) => MapEntry(
              k,
              (e as List<dynamic>).map((e) => e as String).toList(),
            ),
          ),
        ),
      );
      return val;
    });

Map<String, dynamic> _$BrowserGuardSitesToJson(BrowserGuardSites instance) =>
    <String, dynamic>{'hosts': instance.hosts};

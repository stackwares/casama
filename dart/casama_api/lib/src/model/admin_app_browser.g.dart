// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_app_browser.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminAppBrowserCWProxy {
  AdminAppBrowser settings(AppBrowserSettings settings);

  AdminAppBrowser numbers(AppBrowserNumbers numbers);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminAppBrowser(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminAppBrowser(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminAppBrowser call({
    AppBrowserSettings settings,
    AppBrowserNumbers numbers,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminAppBrowser.copyWith(...)` or call `instanceOfAdminAppBrowser.copyWith.fieldName(value)` for a single field.
class _$AdminAppBrowserCWProxyImpl implements _$AdminAppBrowserCWProxy {
  const _$AdminAppBrowserCWProxyImpl(this._value);

  final AdminAppBrowser _value;

  @override
  AdminAppBrowser settings(AppBrowserSettings settings) =>
      call(settings: settings);

  @override
  AdminAppBrowser numbers(AppBrowserNumbers numbers) => call(numbers: numbers);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminAppBrowser(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminAppBrowser(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminAppBrowser call({
    Object? settings = const $CopyWithPlaceholder(),
    Object? numbers = const $CopyWithPlaceholder(),
  }) {
    return AdminAppBrowser(
      settings: settings == const $CopyWithPlaceholder() || settings == null
          ? _value.settings
          // ignore: cast_nullable_to_non_nullable
          : settings as AppBrowserSettings,
      numbers: numbers == const $CopyWithPlaceholder() || numbers == null
          ? _value.numbers
          // ignore: cast_nullable_to_non_nullable
          : numbers as AppBrowserNumbers,
    );
  }
}

extension $AdminAppBrowserCopyWith on AdminAppBrowser {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminAppBrowser.copyWith(...)` or `instanceOfAdminAppBrowser.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminAppBrowserCWProxy get copyWith => _$AdminAppBrowserCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminAppBrowser _$AdminAppBrowserFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminAppBrowser', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['settings', 'numbers']);
      final val = AdminAppBrowser(
        settings: $checkedConvert(
          'settings',
          (v) => AppBrowserSettings.fromJson(v as Map<String, dynamic>),
        ),
        numbers: $checkedConvert(
          'numbers',
          (v) => AppBrowserNumbers.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdminAppBrowserToJson(AdminAppBrowser instance) =>
    <String, dynamic>{
      'settings': instance.settings.toJson(),
      'numbers': instance.numbers.toJson(),
    };

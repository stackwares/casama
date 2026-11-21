// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_browser_state.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppBrowserStateCWProxy {
  AppBrowserState available(bool available);

  AppBrowserState reason(String? reason);

  AppBrowserState device(LocalDevice? device);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppBrowserState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppBrowserState(...).copyWith(id: 12, name: "My name")
  /// ```
  AppBrowserState call({bool available, String? reason, LocalDevice? device});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAppBrowserState.copyWith(...)` or call `instanceOfAppBrowserState.copyWith.fieldName(value)` for a single field.
class _$AppBrowserStateCWProxyImpl implements _$AppBrowserStateCWProxy {
  const _$AppBrowserStateCWProxyImpl(this._value);

  final AppBrowserState _value;

  @override
  AppBrowserState available(bool available) => call(available: available);

  @override
  AppBrowserState reason(String? reason) => call(reason: reason);

  @override
  AppBrowserState device(LocalDevice? device) => call(device: device);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppBrowserState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppBrowserState(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AppBrowserState call({
    Object? available = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? device = const $CopyWithPlaceholder(),
  }) {
    return AppBrowserState(
      available: available == const $CopyWithPlaceholder() || available == null
          ? _value.available
          // ignore: cast_nullable_to_non_nullable
          : available as bool,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String?,
      device: device == const $CopyWithPlaceholder()
          ? _value.device
          // ignore: cast_nullable_to_non_nullable
          : device as LocalDevice?,
    );
  }
}

extension $AppBrowserStateCopyWith on AppBrowserState {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAppBrowserState.copyWith(...)` or `instanceOfAppBrowserState.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppBrowserStateCWProxy get copyWith => _$AppBrowserStateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppBrowserState _$AppBrowserStateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AppBrowserState', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['available', 'reason', 'device']);
      final val = AppBrowserState(
        available: $checkedConvert('available', (v) => v as bool),
        reason: $checkedConvert('reason', (v) => v as String?),
        device: $checkedConvert(
          'device',
          (v) => v == null
              ? null
              : LocalDevice.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AppBrowserStateToJson(AppBrowserState instance) =>
    <String, dynamic>{
      'available': instance.available,
      'reason': instance.reason,
      'device': instance.device?.toJson(),
    };

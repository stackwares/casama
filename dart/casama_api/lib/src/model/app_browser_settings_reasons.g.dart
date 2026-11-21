// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_browser_settings_reasons.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppBrowserSettingsReasonsCWProxy {
  AppBrowserSettingsReasons asked(bool asked);

  AppBrowserSettingsReasons blocked(bool blocked);

  AppBrowserSettingsReasons signedIn(bool signedIn);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppBrowserSettingsReasons(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppBrowserSettingsReasons(...).copyWith(id: 12, name: "My name")
  /// ```
  AppBrowserSettingsReasons call({bool asked, bool blocked, bool signedIn});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAppBrowserSettingsReasons.copyWith(...)` or call `instanceOfAppBrowserSettingsReasons.copyWith.fieldName(value)` for a single field.
class _$AppBrowserSettingsReasonsCWProxyImpl
    implements _$AppBrowserSettingsReasonsCWProxy {
  const _$AppBrowserSettingsReasonsCWProxyImpl(this._value);

  final AppBrowserSettingsReasons _value;

  @override
  AppBrowserSettingsReasons asked(bool asked) => call(asked: asked);

  @override
  AppBrowserSettingsReasons blocked(bool blocked) => call(blocked: blocked);

  @override
  AppBrowserSettingsReasons signedIn(bool signedIn) => call(signedIn: signedIn);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppBrowserSettingsReasons(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppBrowserSettingsReasons(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AppBrowserSettingsReasons call({
    Object? asked = const $CopyWithPlaceholder(),
    Object? blocked = const $CopyWithPlaceholder(),
    Object? signedIn = const $CopyWithPlaceholder(),
  }) {
    return AppBrowserSettingsReasons(
      asked: asked == const $CopyWithPlaceholder() || asked == null
          ? _value.asked
          // ignore: cast_nullable_to_non_nullable
          : asked as bool,
      blocked: blocked == const $CopyWithPlaceholder() || blocked == null
          ? _value.blocked
          // ignore: cast_nullable_to_non_nullable
          : blocked as bool,
      signedIn: signedIn == const $CopyWithPlaceholder() || signedIn == null
          ? _value.signedIn
          // ignore: cast_nullable_to_non_nullable
          : signedIn as bool,
    );
  }
}

extension $AppBrowserSettingsReasonsCopyWith on AppBrowserSettingsReasons {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAppBrowserSettingsReasons.copyWith(...)` or `instanceOfAppBrowserSettingsReasons.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppBrowserSettingsReasonsCWProxy get copyWith =>
      _$AppBrowserSettingsReasonsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppBrowserSettingsReasons _$AppBrowserSettingsReasonsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AppBrowserSettingsReasons', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['asked', 'blocked', 'signed_in']);
  final val = AppBrowserSettingsReasons(
    asked: $checkedConvert('asked', (v) => v as bool),
    blocked: $checkedConvert('blocked', (v) => v as bool),
    signedIn: $checkedConvert('signed_in', (v) => v as bool),
  );
  return val;
}, fieldKeyMap: const {'signedIn': 'signed_in'});

Map<String, dynamic> _$AppBrowserSettingsReasonsToJson(
  AppBrowserSettingsReasons instance,
) => <String, dynamic>{
  'asked': instance.asked,
  'blocked': instance.blocked,
  'signed_in': instance.signedIn,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_app_browser_request_reasons.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SaveAppBrowserRequestReasonsCWProxy {
  SaveAppBrowserRequestReasons asked(bool? asked);

  SaveAppBrowserRequestReasons blocked(bool? blocked);

  SaveAppBrowserRequestReasons signedIn(bool? signedIn);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveAppBrowserRequestReasons(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveAppBrowserRequestReasons(...).copyWith(id: 12, name: "My name")
  /// ```
  SaveAppBrowserRequestReasons call({
    bool? asked,
    bool? blocked,
    bool? signedIn,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSaveAppBrowserRequestReasons.copyWith(...)` or call `instanceOfSaveAppBrowserRequestReasons.copyWith.fieldName(value)` for a single field.
class _$SaveAppBrowserRequestReasonsCWProxyImpl
    implements _$SaveAppBrowserRequestReasonsCWProxy {
  const _$SaveAppBrowserRequestReasonsCWProxyImpl(this._value);

  final SaveAppBrowserRequestReasons _value;

  @override
  SaveAppBrowserRequestReasons asked(bool? asked) => call(asked: asked);

  @override
  SaveAppBrowserRequestReasons blocked(bool? blocked) => call(blocked: blocked);

  @override
  SaveAppBrowserRequestReasons signedIn(bool? signedIn) =>
      call(signedIn: signedIn);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveAppBrowserRequestReasons(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveAppBrowserRequestReasons(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SaveAppBrowserRequestReasons call({
    Object? asked = const $CopyWithPlaceholder(),
    Object? blocked = const $CopyWithPlaceholder(),
    Object? signedIn = const $CopyWithPlaceholder(),
  }) {
    return SaveAppBrowserRequestReasons(
      asked: asked == const $CopyWithPlaceholder()
          ? _value.asked
          // ignore: cast_nullable_to_non_nullable
          : asked as bool?,
      blocked: blocked == const $CopyWithPlaceholder()
          ? _value.blocked
          // ignore: cast_nullable_to_non_nullable
          : blocked as bool?,
      signedIn: signedIn == const $CopyWithPlaceholder()
          ? _value.signedIn
          // ignore: cast_nullable_to_non_nullable
          : signedIn as bool?,
    );
  }
}

extension $SaveAppBrowserRequestReasonsCopyWith
    on SaveAppBrowserRequestReasons {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSaveAppBrowserRequestReasons.copyWith(...)` or `instanceOfSaveAppBrowserRequestReasons.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SaveAppBrowserRequestReasonsCWProxy get copyWith =>
      _$SaveAppBrowserRequestReasonsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveAppBrowserRequestReasons _$SaveAppBrowserRequestReasonsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SaveAppBrowserRequestReasons', json, ($checkedConvert) {
  final val = SaveAppBrowserRequestReasons(
    asked: $checkedConvert('asked', (v) => v as bool?),
    blocked: $checkedConvert('blocked', (v) => v as bool?),
    signedIn: $checkedConvert('signed_in', (v) => v as bool?),
  );
  return val;
}, fieldKeyMap: const {'signedIn': 'signed_in'});

Map<String, dynamic> _$SaveAppBrowserRequestReasonsToJson(
  SaveAppBrowserRequestReasons instance,
) => <String, dynamic>{
  'asked': ?instance.asked,
  'blocked': ?instance.blocked,
  'signed_in': ?instance.signedIn,
};

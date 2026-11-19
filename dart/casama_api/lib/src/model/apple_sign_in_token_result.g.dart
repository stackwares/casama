// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apple_sign_in_token_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppleSignInTokenResultCWProxy {
  AppleSignInTokenResult stored(bool stored);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppleSignInTokenResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppleSignInTokenResult(...).copyWith(id: 12, name: "My name")
  /// ```
  AppleSignInTokenResult call({bool stored});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAppleSignInTokenResult.copyWith(...)` or call `instanceOfAppleSignInTokenResult.copyWith.fieldName(value)` for a single field.
class _$AppleSignInTokenResultCWProxyImpl
    implements _$AppleSignInTokenResultCWProxy {
  const _$AppleSignInTokenResultCWProxyImpl(this._value);

  final AppleSignInTokenResult _value;

  @override
  AppleSignInTokenResult stored(bool stored) => call(stored: stored);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppleSignInTokenResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppleSignInTokenResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AppleSignInTokenResult call({Object? stored = const $CopyWithPlaceholder()}) {
    return AppleSignInTokenResult(
      stored: stored == const $CopyWithPlaceholder() || stored == null
          ? _value.stored
          // ignore: cast_nullable_to_non_nullable
          : stored as bool,
    );
  }
}

extension $AppleSignInTokenResultCopyWith on AppleSignInTokenResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAppleSignInTokenResult.copyWith(...)` or `instanceOfAppleSignInTokenResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppleSignInTokenResultCWProxy get copyWith =>
      _$AppleSignInTokenResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppleSignInTokenResult _$AppleSignInTokenResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AppleSignInTokenResult', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['stored']);
  final val = AppleSignInTokenResult(
    stored: $checkedConvert('stored', (v) => v as bool),
  );
  return val;
});

Map<String, dynamic> _$AppleSignInTokenResultToJson(
  AppleSignInTokenResult instance,
) => <String, dynamic>{'stored': instance.stored};

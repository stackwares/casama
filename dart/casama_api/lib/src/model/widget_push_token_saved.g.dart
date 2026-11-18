// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'widget_push_token_saved.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WidgetPushTokenSavedCWProxy {
  WidgetPushTokenSaved ok(bool ok);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WidgetPushTokenSaved(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WidgetPushTokenSaved(...).copyWith(id: 12, name: "My name")
  /// ```
  WidgetPushTokenSaved call({bool ok});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWidgetPushTokenSaved.copyWith(...)` or call `instanceOfWidgetPushTokenSaved.copyWith.fieldName(value)` for a single field.
class _$WidgetPushTokenSavedCWProxyImpl
    implements _$WidgetPushTokenSavedCWProxy {
  const _$WidgetPushTokenSavedCWProxyImpl(this._value);

  final WidgetPushTokenSaved _value;

  @override
  WidgetPushTokenSaved ok(bool ok) => call(ok: ok);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WidgetPushTokenSaved(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WidgetPushTokenSaved(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WidgetPushTokenSaved call({Object? ok = const $CopyWithPlaceholder()}) {
    return WidgetPushTokenSaved(
      ok: ok == const $CopyWithPlaceholder() || ok == null
          ? _value.ok
          // ignore: cast_nullable_to_non_nullable
          : ok as bool,
    );
  }
}

extension $WidgetPushTokenSavedCopyWith on WidgetPushTokenSaved {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWidgetPushTokenSaved.copyWith(...)` or `instanceOfWidgetPushTokenSaved.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WidgetPushTokenSavedCWProxy get copyWith =>
      _$WidgetPushTokenSavedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WidgetPushTokenSaved _$WidgetPushTokenSavedFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('WidgetPushTokenSaved', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['ok']);
  final val = WidgetPushTokenSaved(ok: $checkedConvert('ok', (v) => v as bool));
  return val;
});

Map<String, dynamic> _$WidgetPushTokenSavedToJson(
  WidgetPushTokenSaved instance,
) => <String, dynamic>{'ok': instance.ok};

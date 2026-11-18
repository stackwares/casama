// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_self_saved.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchSelfSavedCWProxy {
  WatchSelfSaved ok(bool ok);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchSelfSaved(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchSelfSaved(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchSelfSaved call({bool ok});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchSelfSaved.copyWith(...)` or call `instanceOfWatchSelfSaved.copyWith.fieldName(value)` for a single field.
class _$WatchSelfSavedCWProxyImpl implements _$WatchSelfSavedCWProxy {
  const _$WatchSelfSavedCWProxyImpl(this._value);

  final WatchSelfSaved _value;

  @override
  WatchSelfSaved ok(bool ok) => call(ok: ok);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchSelfSaved(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchSelfSaved(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchSelfSaved call({Object? ok = const $CopyWithPlaceholder()}) {
    return WatchSelfSaved(
      ok: ok == const $CopyWithPlaceholder() || ok == null
          ? _value.ok
          // ignore: cast_nullable_to_non_nullable
          : ok as bool,
    );
  }
}

extension $WatchSelfSavedCopyWith on WatchSelfSaved {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchSelfSaved.copyWith(...)` or `instanceOfWatchSelfSaved.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchSelfSavedCWProxy get copyWith => _$WatchSelfSavedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchSelfSaved _$WatchSelfSavedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WatchSelfSaved', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['ok']);
      final val = WatchSelfSaved(ok: $checkedConvert('ok', (v) => v as bool));
      return val;
    });

Map<String, dynamic> _$WatchSelfSavedToJson(WatchSelfSaved instance) =>
    <String, dynamic>{'ok': instance.ok};

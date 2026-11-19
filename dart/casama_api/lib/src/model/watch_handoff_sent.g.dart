// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_handoff_sent.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchHandoffSentCWProxy {
  WatchHandoffSent sent(int sent);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchHandoffSent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchHandoffSent(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchHandoffSent call({int sent});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchHandoffSent.copyWith(...)` or call `instanceOfWatchHandoffSent.copyWith.fieldName(value)` for a single field.
class _$WatchHandoffSentCWProxyImpl implements _$WatchHandoffSentCWProxy {
  const _$WatchHandoffSentCWProxyImpl(this._value);

  final WatchHandoffSent _value;

  @override
  WatchHandoffSent sent(int sent) => call(sent: sent);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchHandoffSent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchHandoffSent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchHandoffSent call({Object? sent = const $CopyWithPlaceholder()}) {
    return WatchHandoffSent(
      sent: sent == const $CopyWithPlaceholder() || sent == null
          ? _value.sent
          // ignore: cast_nullable_to_non_nullable
          : sent as int,
    );
  }
}

extension $WatchHandoffSentCopyWith on WatchHandoffSent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchHandoffSent.copyWith(...)` or `instanceOfWatchHandoffSent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchHandoffSentCWProxy get copyWith => _$WatchHandoffSentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchHandoffSent _$WatchHandoffSentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WatchHandoffSent', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['sent']);
      final val = WatchHandoffSent(
        sent: $checkedConvert('sent', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$WatchHandoffSentToJson(WatchHandoffSent instance) =>
    <String, dynamic>{'sent': instance.sent};

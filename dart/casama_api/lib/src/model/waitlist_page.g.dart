// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waitlist_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WaitlistPageCWProxy {
  WaitlistPage stats(WaitlistStats stats);

  WaitlistPage gate(SignupGateState gate);

  WaitlistPage items(List<WaitlistEntry> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WaitlistPage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WaitlistPage(...).copyWith(id: 12, name: "My name")
  /// ```
  WaitlistPage call({
    WaitlistStats stats,
    SignupGateState gate,
    List<WaitlistEntry> items,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWaitlistPage.copyWith(...)` or call `instanceOfWaitlistPage.copyWith.fieldName(value)` for a single field.
class _$WaitlistPageCWProxyImpl implements _$WaitlistPageCWProxy {
  const _$WaitlistPageCWProxyImpl(this._value);

  final WaitlistPage _value;

  @override
  WaitlistPage stats(WaitlistStats stats) => call(stats: stats);

  @override
  WaitlistPage gate(SignupGateState gate) => call(gate: gate);

  @override
  WaitlistPage items(List<WaitlistEntry> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WaitlistPage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WaitlistPage(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WaitlistPage call({
    Object? stats = const $CopyWithPlaceholder(),
    Object? gate = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return WaitlistPage(
      stats: stats == const $CopyWithPlaceholder() || stats == null
          ? _value.stats
          // ignore: cast_nullable_to_non_nullable
          : stats as WaitlistStats,
      gate: gate == const $CopyWithPlaceholder() || gate == null
          ? _value.gate
          // ignore: cast_nullable_to_non_nullable
          : gate as SignupGateState,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<WaitlistEntry>,
    );
  }
}

extension $WaitlistPageCopyWith on WaitlistPage {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWaitlistPage.copyWith(...)` or `instanceOfWaitlistPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WaitlistPageCWProxy get copyWith => _$WaitlistPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WaitlistPage _$WaitlistPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WaitlistPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['stats', 'gate', 'items']);
      final val = WaitlistPage(
        stats: $checkedConvert(
          'stats',
          (v) => WaitlistStats.fromJson(v as Map<String, dynamic>),
        ),
        gate: $checkedConvert(
          'gate',
          (v) => SignupGateState.fromJson(v as Map<String, dynamic>),
        ),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => WaitlistEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$WaitlistPageToJson(WaitlistPage instance) =>
    <String, dynamic>{
      'stats': instance.stats.toJson(),
      'gate': instance.gate.toJson(),
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

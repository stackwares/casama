// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'replay_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReplayListCWProxy {
  ReplayList items(List<Replay> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReplayList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReplayList(...).copyWith(id: 12, name: "My name")
  /// ```
  ReplayList call({List<Replay> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReplayList.copyWith(...)` or call `instanceOfReplayList.copyWith.fieldName(value)` for a single field.
class _$ReplayListCWProxyImpl implements _$ReplayListCWProxy {
  const _$ReplayListCWProxyImpl(this._value);

  final ReplayList _value;

  @override
  ReplayList items(List<Replay> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReplayList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReplayList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReplayList call({Object? items = const $CopyWithPlaceholder()}) {
    return ReplayList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Replay>,
    );
  }
}

extension $ReplayListCopyWith on ReplayList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReplayList.copyWith(...)` or `instanceOfReplayList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReplayListCWProxy get copyWith => _$ReplayListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReplayList _$ReplayListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReplayList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ReplayList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Replay.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ReplayListToJson(ReplayList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

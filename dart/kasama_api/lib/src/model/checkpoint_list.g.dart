// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkpoint_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CheckpointListCWProxy {
  CheckpointList items(List<Checkpoint> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CheckpointList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CheckpointList(...).copyWith(id: 12, name: "My name")
  /// ```
  CheckpointList call({List<Checkpoint> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCheckpointList.copyWith(...)` or call `instanceOfCheckpointList.copyWith.fieldName(value)` for a single field.
class _$CheckpointListCWProxyImpl implements _$CheckpointListCWProxy {
  const _$CheckpointListCWProxyImpl(this._value);

  final CheckpointList _value;

  @override
  CheckpointList items(List<Checkpoint> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CheckpointList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CheckpointList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CheckpointList call({Object? items = const $CopyWithPlaceholder()}) {
    return CheckpointList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Checkpoint>,
    );
  }
}

extension $CheckpointListCopyWith on CheckpointList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCheckpointList.copyWith(...)` or `instanceOfCheckpointList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CheckpointListCWProxy get copyWith => _$CheckpointListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckpointList _$CheckpointListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CheckpointList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = CheckpointList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Checkpoint.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CheckpointListToJson(CheckpointList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

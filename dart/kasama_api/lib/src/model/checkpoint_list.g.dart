// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkpoint_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CheckpointListCWProxy {
  CheckpointList items(List<Checkpoint> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CheckpointList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CheckpointList(...).copyWith(id: 12, name: "My name")
  /// ````
  CheckpointList call({List<Checkpoint> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCheckpointList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCheckpointList.copyWith.fieldName(...)`
class _$CheckpointListCWProxyImpl implements _$CheckpointListCWProxy {
  const _$CheckpointListCWProxyImpl(this._value);

  final CheckpointList _value;

  @override
  CheckpointList items(List<Checkpoint> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CheckpointList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CheckpointList(...).copyWith(id: 12, name: "My name")
  /// ````
  CheckpointList call({Object? items = const $CopyWithPlaceholder()}) {
    return CheckpointList(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Checkpoint>,
    );
  }
}

extension $CheckpointListCopyWith on CheckpointList {
  /// Returns a callable class that can be used as follows: `instanceOfCheckpointList.copyWith(...)` or like so:`instanceOfCheckpointList.copyWith.fieldName(...)`.
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

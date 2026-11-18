// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blocked_person_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BlockedPersonListCWProxy {
  BlockedPersonList items(List<BlockedPerson> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BlockedPersonList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BlockedPersonList(...).copyWith(id: 12, name: "My name")
  /// ```
  BlockedPersonList call({List<BlockedPerson> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBlockedPersonList.copyWith(...)` or call `instanceOfBlockedPersonList.copyWith.fieldName(value)` for a single field.
class _$BlockedPersonListCWProxyImpl implements _$BlockedPersonListCWProxy {
  const _$BlockedPersonListCWProxyImpl(this._value);

  final BlockedPersonList _value;

  @override
  BlockedPersonList items(List<BlockedPerson> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BlockedPersonList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BlockedPersonList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BlockedPersonList call({Object? items = const $CopyWithPlaceholder()}) {
    return BlockedPersonList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<BlockedPerson>,
    );
  }
}

extension $BlockedPersonListCopyWith on BlockedPersonList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBlockedPersonList.copyWith(...)` or `instanceOfBlockedPersonList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BlockedPersonListCWProxy get copyWith =>
      _$BlockedPersonListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlockedPersonList _$BlockedPersonListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BlockedPersonList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = BlockedPersonList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => BlockedPerson.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$BlockedPersonListToJson(BlockedPersonList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

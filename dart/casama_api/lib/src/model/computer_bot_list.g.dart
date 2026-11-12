// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_bot_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerBotListCWProxy {
  ComputerBotList items(List<ComputerBotUse> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerBotList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerBotList(...).copyWith(id: 12, name: "My name")
  /// ```
  ComputerBotList call({List<ComputerBotUse> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComputerBotList.copyWith(...)` or call `instanceOfComputerBotList.copyWith.fieldName(value)` for a single field.
class _$ComputerBotListCWProxyImpl implements _$ComputerBotListCWProxy {
  const _$ComputerBotListCWProxyImpl(this._value);

  final ComputerBotList _value;

  @override
  ComputerBotList items(List<ComputerBotUse> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerBotList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerBotList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComputerBotList call({Object? items = const $CopyWithPlaceholder()}) {
    return ComputerBotList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<ComputerBotUse>,
    );
  }
}

extension $ComputerBotListCopyWith on ComputerBotList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComputerBotList.copyWith(...)` or `instanceOfComputerBotList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComputerBotListCWProxy get copyWith => _$ComputerBotListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComputerBotList _$ComputerBotListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ComputerBotList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ComputerBotList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => ComputerBotUse.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ComputerBotListToJson(ComputerBotList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

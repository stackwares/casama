// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coding_agent_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CodingAgentListCWProxy {
  CodingAgentList items(List<CodingAgentInfo> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CodingAgentList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CodingAgentList(...).copyWith(id: 12, name: "My name")
  /// ```
  CodingAgentList call({List<CodingAgentInfo> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCodingAgentList.copyWith(...)` or call `instanceOfCodingAgentList.copyWith.fieldName(value)` for a single field.
class _$CodingAgentListCWProxyImpl implements _$CodingAgentListCWProxy {
  const _$CodingAgentListCWProxyImpl(this._value);

  final CodingAgentList _value;

  @override
  CodingAgentList items(List<CodingAgentInfo> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CodingAgentList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CodingAgentList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CodingAgentList call({Object? items = const $CopyWithPlaceholder()}) {
    return CodingAgentList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<CodingAgentInfo>,
    );
  }
}

extension $CodingAgentListCopyWith on CodingAgentList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCodingAgentList.copyWith(...)` or `instanceOfCodingAgentList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CodingAgentListCWProxy get copyWith => _$CodingAgentListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CodingAgentList _$CodingAgentListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CodingAgentList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = CodingAgentList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => CodingAgentInfo.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CodingAgentListToJson(CodingAgentList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

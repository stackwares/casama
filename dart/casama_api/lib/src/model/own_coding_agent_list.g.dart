// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'own_coding_agent_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OwnCodingAgentListCWProxy {
  OwnCodingAgentList items(List<OwnCodingAgentEntry> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OwnCodingAgentList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OwnCodingAgentList(...).copyWith(id: 12, name: "My name")
  /// ```
  OwnCodingAgentList call({List<OwnCodingAgentEntry> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfOwnCodingAgentList.copyWith(...)` or call `instanceOfOwnCodingAgentList.copyWith.fieldName(value)` for a single field.
class _$OwnCodingAgentListCWProxyImpl implements _$OwnCodingAgentListCWProxy {
  const _$OwnCodingAgentListCWProxyImpl(this._value);

  final OwnCodingAgentList _value;

  @override
  OwnCodingAgentList items(List<OwnCodingAgentEntry> items) =>
      call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OwnCodingAgentList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OwnCodingAgentList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  OwnCodingAgentList call({Object? items = const $CopyWithPlaceholder()}) {
    return OwnCodingAgentList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<OwnCodingAgentEntry>,
    );
  }
}

extension $OwnCodingAgentListCopyWith on OwnCodingAgentList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfOwnCodingAgentList.copyWith(...)` or `instanceOfOwnCodingAgentList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OwnCodingAgentListCWProxy get copyWith =>
      _$OwnCodingAgentListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OwnCodingAgentList _$OwnCodingAgentListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OwnCodingAgentList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = OwnCodingAgentList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => OwnCodingAgentEntry.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$OwnCodingAgentListToJson(OwnCodingAgentList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

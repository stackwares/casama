// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_request_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$JoinRequestListCWProxy {
  JoinRequestList items(List<JoinRequest> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `JoinRequestList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// JoinRequestList(...).copyWith(id: 12, name: "My name")
  /// ```
  JoinRequestList call({List<JoinRequest> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfJoinRequestList.copyWith(...)` or call `instanceOfJoinRequestList.copyWith.fieldName(value)` for a single field.
class _$JoinRequestListCWProxyImpl implements _$JoinRequestListCWProxy {
  const _$JoinRequestListCWProxyImpl(this._value);

  final JoinRequestList _value;

  @override
  JoinRequestList items(List<JoinRequest> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `JoinRequestList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// JoinRequestList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  JoinRequestList call({Object? items = const $CopyWithPlaceholder()}) {
    return JoinRequestList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<JoinRequest>,
    );
  }
}

extension $JoinRequestListCopyWith on JoinRequestList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfJoinRequestList.copyWith(...)` or `instanceOfJoinRequestList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$JoinRequestListCWProxy get copyWith => _$JoinRequestListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JoinRequestList _$JoinRequestListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('JoinRequestList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = JoinRequestList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => JoinRequest.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$JoinRequestListToJson(JoinRequestList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

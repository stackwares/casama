// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_user_facts_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AddUserFactsRequestCWProxy {
  AddUserFactsRequest items(List<AddUserFactsRequestItemsInner> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AddUserFactsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AddUserFactsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  AddUserFactsRequest call({List<AddUserFactsRequestItemsInner> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAddUserFactsRequest.copyWith(...)` or call `instanceOfAddUserFactsRequest.copyWith.fieldName(value)` for a single field.
class _$AddUserFactsRequestCWProxyImpl implements _$AddUserFactsRequestCWProxy {
  const _$AddUserFactsRequestCWProxyImpl(this._value);

  final AddUserFactsRequest _value;

  @override
  AddUserFactsRequest items(List<AddUserFactsRequestItemsInner> items) =>
      call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AddUserFactsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AddUserFactsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AddUserFactsRequest call({Object? items = const $CopyWithPlaceholder()}) {
    return AddUserFactsRequest(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AddUserFactsRequestItemsInner>,
    );
  }
}

extension $AddUserFactsRequestCopyWith on AddUserFactsRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAddUserFactsRequest.copyWith(...)` or `instanceOfAddUserFactsRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AddUserFactsRequestCWProxy get copyWith =>
      _$AddUserFactsRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddUserFactsRequest _$AddUserFactsRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AddUserFactsRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = AddUserFactsRequest(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => AddUserFactsRequestItemsInner.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AddUserFactsRequestToJson(
  AddUserFactsRequest instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

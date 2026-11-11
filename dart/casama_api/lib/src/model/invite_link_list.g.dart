// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_link_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InviteLinkListCWProxy {
  InviteLinkList items(List<InviteLink> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteLinkList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteLinkList(...).copyWith(id: 12, name: "My name")
  /// ```
  InviteLinkList call({List<InviteLink> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInviteLinkList.copyWith(...)` or call `instanceOfInviteLinkList.copyWith.fieldName(value)` for a single field.
class _$InviteLinkListCWProxyImpl implements _$InviteLinkListCWProxy {
  const _$InviteLinkListCWProxyImpl(this._value);

  final InviteLinkList _value;

  @override
  InviteLinkList items(List<InviteLink> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteLinkList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteLinkList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  InviteLinkList call({Object? items = const $CopyWithPlaceholder()}) {
    return InviteLinkList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<InviteLink>,
    );
  }
}

extension $InviteLinkListCopyWith on InviteLinkList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInviteLinkList.copyWith(...)` or `instanceOfInviteLinkList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InviteLinkListCWProxy get copyWith => _$InviteLinkListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InviteLinkList _$InviteLinkListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('InviteLinkList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = InviteLinkList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => InviteLink.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$InviteLinkListToJson(InviteLinkList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

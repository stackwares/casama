// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InviteListCWProxy {
  InviteList items(List<Invite> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteList(...).copyWith(id: 12, name: "My name")
  /// ```
  InviteList call({List<Invite> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInviteList.copyWith(...)` or call `instanceOfInviteList.copyWith.fieldName(value)` for a single field.
class _$InviteListCWProxyImpl implements _$InviteListCWProxy {
  const _$InviteListCWProxyImpl(this._value);

  final InviteList _value;

  @override
  InviteList items(List<Invite> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  InviteList call({Object? items = const $CopyWithPlaceholder()}) {
    return InviteList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Invite>,
    );
  }
}

extension $InviteListCopyWith on InviteList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInviteList.copyWith(...)` or `instanceOfInviteList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InviteListCWProxy get copyWith => _$InviteListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InviteList _$InviteListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('InviteList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = InviteList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Invite.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$InviteListToJson(InviteList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

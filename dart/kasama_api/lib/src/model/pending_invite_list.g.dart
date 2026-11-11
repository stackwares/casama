// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_invite_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PendingInviteListCWProxy {
  PendingInviteList items(List<PendingInvite> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PendingInviteList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PendingInviteList(...).copyWith(id: 12, name: "My name")
  /// ```
  PendingInviteList call({List<PendingInvite> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPendingInviteList.copyWith(...)` or call `instanceOfPendingInviteList.copyWith.fieldName(value)` for a single field.
class _$PendingInviteListCWProxyImpl implements _$PendingInviteListCWProxy {
  const _$PendingInviteListCWProxyImpl(this._value);

  final PendingInviteList _value;

  @override
  PendingInviteList items(List<PendingInvite> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PendingInviteList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PendingInviteList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PendingInviteList call({Object? items = const $CopyWithPlaceholder()}) {
    return PendingInviteList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<PendingInvite>,
    );
  }
}

extension $PendingInviteListCopyWith on PendingInviteList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPendingInviteList.copyWith(...)` or `instanceOfPendingInviteList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PendingInviteListCWProxy get copyWith =>
      _$PendingInviteListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PendingInviteList _$PendingInviteListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PendingInviteList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = PendingInviteList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => PendingInvite.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PendingInviteListToJson(PendingInviteList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_campaign_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InviteCampaignListCWProxy {
  InviteCampaignList items(List<InviteCampaign> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteCampaignList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteCampaignList(...).copyWith(id: 12, name: "My name")
  /// ```
  InviteCampaignList call({List<InviteCampaign> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInviteCampaignList.copyWith(...)` or call `instanceOfInviteCampaignList.copyWith.fieldName(value)` for a single field.
class _$InviteCampaignListCWProxyImpl implements _$InviteCampaignListCWProxy {
  const _$InviteCampaignListCWProxyImpl(this._value);

  final InviteCampaignList _value;

  @override
  InviteCampaignList items(List<InviteCampaign> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteCampaignList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteCampaignList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  InviteCampaignList call({Object? items = const $CopyWithPlaceholder()}) {
    return InviteCampaignList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<InviteCampaign>,
    );
  }
}

extension $InviteCampaignListCopyWith on InviteCampaignList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInviteCampaignList.copyWith(...)` or `instanceOfInviteCampaignList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InviteCampaignListCWProxy get copyWith =>
      _$InviteCampaignListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InviteCampaignList _$InviteCampaignListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('InviteCampaignList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = InviteCampaignList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => InviteCampaign.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$InviteCampaignListToJson(InviteCampaignList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_mail_addresses200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminMailAddresses200ResponseCWProxy {
  AdminMailAddresses200Response items(List<AdminMailAddress> items);

  AdminMailAddresses200Response sentToday(int? sentToday);

  AdminMailAddresses200Response sendCeiling(int? sendCeiling);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMailAddresses200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMailAddresses200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminMailAddresses200Response call({
    List<AdminMailAddress> items,
    int? sentToday,
    int? sendCeiling,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminMailAddresses200Response.copyWith(...)` or call `instanceOfAdminMailAddresses200Response.copyWith.fieldName(value)` for a single field.
class _$AdminMailAddresses200ResponseCWProxyImpl
    implements _$AdminMailAddresses200ResponseCWProxy {
  const _$AdminMailAddresses200ResponseCWProxyImpl(this._value);

  final AdminMailAddresses200Response _value;

  @override
  AdminMailAddresses200Response items(List<AdminMailAddress> items) =>
      call(items: items);

  @override
  AdminMailAddresses200Response sentToday(int? sentToday) =>
      call(sentToday: sentToday);

  @override
  AdminMailAddresses200Response sendCeiling(int? sendCeiling) =>
      call(sendCeiling: sendCeiling);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMailAddresses200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMailAddresses200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminMailAddresses200Response call({
    Object? items = const $CopyWithPlaceholder(),
    Object? sentToday = const $CopyWithPlaceholder(),
    Object? sendCeiling = const $CopyWithPlaceholder(),
  }) {
    return AdminMailAddresses200Response(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AdminMailAddress>,
      sentToday: sentToday == const $CopyWithPlaceholder()
          ? _value.sentToday
          // ignore: cast_nullable_to_non_nullable
          : sentToday as int?,
      sendCeiling: sendCeiling == const $CopyWithPlaceholder()
          ? _value.sendCeiling
          // ignore: cast_nullable_to_non_nullable
          : sendCeiling as int?,
    );
  }
}

extension $AdminMailAddresses200ResponseCopyWith
    on AdminMailAddresses200Response {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminMailAddresses200Response.copyWith(...)` or `instanceOfAdminMailAddresses200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminMailAddresses200ResponseCWProxy get copyWith =>
      _$AdminMailAddresses200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminMailAddresses200Response _$AdminMailAddresses200ResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'AdminMailAddresses200Response',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['items']);
    final val = AdminMailAddresses200Response(
      items: $checkedConvert(
        'items',
        (v) => (v as List<dynamic>)
            .map((e) => AdminMailAddress.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      sentToday: $checkedConvert('sent_today', (v) => (v as num?)?.toInt()),
      sendCeiling: $checkedConvert('send_ceiling', (v) => (v as num?)?.toInt()),
    );
    return val;
  },
  fieldKeyMap: const {'sentToday': 'sent_today', 'sendCeiling': 'send_ceiling'},
);

Map<String, dynamic> _$AdminMailAddresses200ResponseToJson(
  AdminMailAddresses200Response instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'sent_today': ?instance.sentToday,
  'send_ceiling': ?instance.sendCeiling,
};

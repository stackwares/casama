// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_secret_request_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotSecretRequestListCWProxy {
  BotSecretRequestList items(List<BotSecretRequest> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotSecretRequestList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotSecretRequestList(...).copyWith(id: 12, name: "My name")
  /// ```
  BotSecretRequestList call({List<BotSecretRequest> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotSecretRequestList.copyWith(...)` or call `instanceOfBotSecretRequestList.copyWith.fieldName(value)` for a single field.
class _$BotSecretRequestListCWProxyImpl
    implements _$BotSecretRequestListCWProxy {
  const _$BotSecretRequestListCWProxyImpl(this._value);

  final BotSecretRequestList _value;

  @override
  BotSecretRequestList items(List<BotSecretRequest> items) =>
      call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotSecretRequestList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotSecretRequestList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotSecretRequestList call({Object? items = const $CopyWithPlaceholder()}) {
    return BotSecretRequestList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<BotSecretRequest>,
    );
  }
}

extension $BotSecretRequestListCopyWith on BotSecretRequestList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotSecretRequestList.copyWith(...)` or `instanceOfBotSecretRequestList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotSecretRequestListCWProxy get copyWith =>
      _$BotSecretRequestListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotSecretRequestList _$BotSecretRequestListFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('BotSecretRequestList', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = BotSecretRequestList(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => BotSecretRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$BotSecretRequestListToJson(
  BotSecretRequestList instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

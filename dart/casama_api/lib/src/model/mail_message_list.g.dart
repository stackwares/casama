// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mail_message_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MailMessageListCWProxy {
  MailMessageList items(List<MailMessage> items);

  MailMessageList nextCursor(String? nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MailMessageList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MailMessageList(...).copyWith(id: 12, name: "My name")
  /// ```
  MailMessageList call({List<MailMessage> items, String? nextCursor});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMailMessageList.copyWith(...)` or call `instanceOfMailMessageList.copyWith.fieldName(value)` for a single field.
class _$MailMessageListCWProxyImpl implements _$MailMessageListCWProxy {
  const _$MailMessageListCWProxyImpl(this._value);

  final MailMessageList _value;

  @override
  MailMessageList items(List<MailMessage> items) => call(items: items);

  @override
  MailMessageList nextCursor(String? nextCursor) =>
      call(nextCursor: nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MailMessageList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MailMessageList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MailMessageList call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return MailMessageList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<MailMessage>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $MailMessageListCopyWith on MailMessageList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMailMessageList.copyWith(...)` or `instanceOfMailMessageList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MailMessageListCWProxy get copyWith => _$MailMessageListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MailMessageList _$MailMessageListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MailMessageList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'next_cursor']);
      final val = MailMessageList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => MailMessage.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'nextCursor': 'next_cursor'});

Map<String, dynamic> _$MailMessageListToJson(MailMessageList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'next_cursor': instance.nextCursor,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_ticket.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SupportTicketCWProxy {
  SupportTicket reference(String reference);

  SupportTicket replyTo(String replyTo);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportTicket(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportTicket(...).copyWith(id: 12, name: "My name")
  /// ```
  SupportTicket call({String reference, String replyTo});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSupportTicket.copyWith(...)` or call `instanceOfSupportTicket.copyWith.fieldName(value)` for a single field.
class _$SupportTicketCWProxyImpl implements _$SupportTicketCWProxy {
  const _$SupportTicketCWProxyImpl(this._value);

  final SupportTicket _value;

  @override
  SupportTicket reference(String reference) => call(reference: reference);

  @override
  SupportTicket replyTo(String replyTo) => call(replyTo: replyTo);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportTicket(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportTicket(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SupportTicket call({
    Object? reference = const $CopyWithPlaceholder(),
    Object? replyTo = const $CopyWithPlaceholder(),
  }) {
    return SupportTicket(
      reference: reference == const $CopyWithPlaceholder() || reference == null
          ? _value.reference
          // ignore: cast_nullable_to_non_nullable
          : reference as String,
      replyTo: replyTo == const $CopyWithPlaceholder() || replyTo == null
          ? _value.replyTo
          // ignore: cast_nullable_to_non_nullable
          : replyTo as String,
    );
  }
}

extension $SupportTicketCopyWith on SupportTicket {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSupportTicket.copyWith(...)` or `instanceOfSupportTicket.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SupportTicketCWProxy get copyWith => _$SupportTicketCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportTicket _$SupportTicketFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SupportTicket', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reference', 'reply_to']);
      final val = SupportTicket(
        reference: $checkedConvert('reference', (v) => v as String),
        replyTo: $checkedConvert('reply_to', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'replyTo': 'reply_to'});

Map<String, dynamic> _$SupportTicketToJson(SupportTicket instance) =>
    <String, dynamic>{
      'reference': instance.reference,
      'reply_to': instance.replyTo,
    };

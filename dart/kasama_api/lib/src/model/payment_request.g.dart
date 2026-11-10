// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PaymentRequestCWProxy {
  PaymentRequest id(String id);

  PaymentRequest botId(String botId);

  PaymentRequest merchant(String merchant);

  PaymentRequest amountCents(int amountCents);

  PaymentRequest currency(String currency);

  PaymentRequest reason(String reason);

  PaymentRequest status(PaymentRequestStatusEnum status);

  PaymentRequest last4(String? last4);

  PaymentRequest spentCents(int? spentCents);

  PaymentRequest expiresAt(DateTime expiresAt);

  PaymentRequest createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PaymentRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PaymentRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  PaymentRequest call({
    String id,
    String botId,
    String merchant,
    int amountCents,
    String currency,
    String reason,
    PaymentRequestStatusEnum status,
    String? last4,
    int? spentCents,
    DateTime expiresAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPaymentRequest.copyWith(...)` or call `instanceOfPaymentRequest.copyWith.fieldName(value)` for a single field.
class _$PaymentRequestCWProxyImpl implements _$PaymentRequestCWProxy {
  const _$PaymentRequestCWProxyImpl(this._value);

  final PaymentRequest _value;

  @override
  PaymentRequest id(String id) => call(id: id);

  @override
  PaymentRequest botId(String botId) => call(botId: botId);

  @override
  PaymentRequest merchant(String merchant) => call(merchant: merchant);

  @override
  PaymentRequest amountCents(int amountCents) => call(amountCents: amountCents);

  @override
  PaymentRequest currency(String currency) => call(currency: currency);

  @override
  PaymentRequest reason(String reason) => call(reason: reason);

  @override
  PaymentRequest status(PaymentRequestStatusEnum status) =>
      call(status: status);

  @override
  PaymentRequest last4(String? last4) => call(last4: last4);

  @override
  PaymentRequest spentCents(int? spentCents) => call(spentCents: spentCents);

  @override
  PaymentRequest expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  @override
  PaymentRequest createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PaymentRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PaymentRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PaymentRequest call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? merchant = const $CopyWithPlaceholder(),
    Object? amountCents = const $CopyWithPlaceholder(),
    Object? currency = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? last4 = const $CopyWithPlaceholder(),
    Object? spentCents = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return PaymentRequest(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      merchant: merchant == const $CopyWithPlaceholder() || merchant == null
          ? _value.merchant
          // ignore: cast_nullable_to_non_nullable
          : merchant as String,
      amountCents:
          amountCents == const $CopyWithPlaceholder() || amountCents == null
          ? _value.amountCents
          // ignore: cast_nullable_to_non_nullable
          : amountCents as int,
      currency: currency == const $CopyWithPlaceholder() || currency == null
          ? _value.currency
          // ignore: cast_nullable_to_non_nullable
          : currency as String,
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as PaymentRequestStatusEnum,
      last4: last4 == const $CopyWithPlaceholder()
          ? _value.last4
          // ignore: cast_nullable_to_non_nullable
          : last4 as String?,
      spentCents: spentCents == const $CopyWithPlaceholder()
          ? _value.spentCents
          // ignore: cast_nullable_to_non_nullable
          : spentCents as int?,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $PaymentRequestCopyWith on PaymentRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPaymentRequest.copyWith(...)` or `instanceOfPaymentRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PaymentRequestCWProxy get copyWith => _$PaymentRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentRequest _$PaymentRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PaymentRequest',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'bot_id',
        'merchant',
        'amount_cents',
        'currency',
        'reason',
        'status',
        'last4',
        'spent_cents',
        'expires_at',
        'created_at',
      ],
    );
    final val = PaymentRequest(
      id: $checkedConvert('id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      merchant: $checkedConvert('merchant', (v) => v as String),
      amountCents: $checkedConvert('amount_cents', (v) => (v as num).toInt()),
      currency: $checkedConvert('currency', (v) => v as String),
      reason: $checkedConvert('reason', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$PaymentRequestStatusEnumEnumMap, v),
      ),
      last4: $checkedConvert('last4', (v) => v as String?),
      spentCents: $checkedConvert('spent_cents', (v) => (v as num?)?.toInt()),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => DateTime.parse(v as String),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'amountCents': 'amount_cents',
    'spentCents': 'spent_cents',
    'expiresAt': 'expires_at',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$PaymentRequestToJson(PaymentRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bot_id': instance.botId,
      'merchant': instance.merchant,
      'amount_cents': instance.amountCents,
      'currency': instance.currency,
      'reason': instance.reason,
      'status': _$PaymentRequestStatusEnumEnumMap[instance.status]!,
      'last4': instance.last4,
      'spent_cents': instance.spentCents,
      'expires_at': instance.expiresAt.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$PaymentRequestStatusEnumEnumMap = {
  PaymentRequestStatusEnum.requested: 'requested',
  PaymentRequestStatusEnum.issued: 'issued',
  PaymentRequestStatusEnum.used: 'used',
  PaymentRequestStatusEnum.declined: 'declined',
  PaymentRequestStatusEnum.expired: 'expired',
  PaymentRequestStatusEnum.failed: 'failed',
  PaymentRequestStatusEnum.canceled: 'canceled',
};

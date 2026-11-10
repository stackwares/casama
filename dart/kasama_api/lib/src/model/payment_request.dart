//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'payment_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentRequest {
  /// Returns a new [PaymentRequest] instance.
  PaymentRequest({

    required  this.id,

    required  this.botId,

    required  this.merchant,

    required  this.amountCents,

    required  this.currency,

    required  this.reason,

    required  this.status,

    required  this.last4,

    required  this.spentCents,

    required  this.expiresAt,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'merchant',
    required: true,
    includeIfNull: false,
  )


  final String merchant;



  @JsonKey(
    
    name: r'amount_cents',
    required: true,
    includeIfNull: false,
  )


  final int amountCents;



  @JsonKey(
    
    name: r'currency',
    required: true,
    includeIfNull: false,
  )


  final String currency;



  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: false,
  )


  final String reason;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final PaymentRequestStatusEnum status;



  @JsonKey(
    
    name: r'last4',
    required: true,
    includeIfNull: true,
  )


  final String? last4;



  @JsonKey(
    
    name: r'spent_cents',
    required: true,
    includeIfNull: true,
  )


  final int? spentCents;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PaymentRequest &&
      other.id == id &&
      other.botId == botId &&
      other.merchant == merchant &&
      other.amountCents == amountCents &&
      other.currency == currency &&
      other.reason == reason &&
      other.status == status &&
      other.last4 == last4 &&
      other.spentCents == spentCents &&
      other.expiresAt == expiresAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        merchant.hashCode +
        amountCents.hashCode +
        currency.hashCode +
        reason.hashCode +
        status.hashCode +
        (last4 == null ? 0 : last4.hashCode) +
        (spentCents == null ? 0 : spentCents.hashCode) +
        expiresAt.hashCode +
        createdAt.hashCode;

  factory PaymentRequest.fromJson(Map<String, dynamic> json) => _$PaymentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PaymentRequestStatusEnum {
@JsonValue(r'requested')
requested(r'requested'),
@JsonValue(r'issued')
issued(r'issued'),
@JsonValue(r'used')
used(r'used'),
@JsonValue(r'declined')
declined(r'declined'),
@JsonValue(r'expired')
expired(r'expired'),
@JsonValue(r'failed')
failed(r'failed'),
@JsonValue(r'canceled')
canceled(r'canceled');

const PaymentRequestStatusEnum(this.value);

final String value;

@override
String toString() => value;
}



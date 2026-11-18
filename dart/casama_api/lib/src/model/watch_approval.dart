//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/watch_risk.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_approval.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchApproval {
  /// Returns a new [WatchApproval] instance.
  WatchApproval({

    required  this.id,

    required  this.runId,

    required  this.botId,

    required  this.bot,

    required  this.botAvatar,

    required  this.status,

    required  this.title,

    required  this.details,

    required  this.risk,

    required  this.payment,

    required  this.canAllow,

    required  this.whyPhone,

    required  this.createdAt,

    required  this.expiresAt,

    required  this.link,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'run_id',
    required: true,
    includeIfNull: false,
  )


  final String runId;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'bot',
    required: true,
    includeIfNull: false,
  )


  final String bot;



  @JsonKey(
    
    name: r'bot_avatar',
    required: true,
    includeIfNull: false,
  )


  final String botAvatar;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final WatchApprovalStatusEnum status;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'details',
    required: true,
    includeIfNull: false,
  )


  final List<String> details;



  @JsonKey(
    
    name: r'risk',
    required: true,
    includeIfNull: false,
  )


  final WatchRisk risk;



  @JsonKey(
    
    name: r'payment',
    required: true,
    includeIfNull: false,
  )


  final bool payment;



  @JsonKey(
    
    name: r'can_allow',
    required: true,
    includeIfNull: false,
  )


  final WatchApprovalCanAllowEnum canAllow;



  @JsonKey(
    
    name: r'why_phone',
    required: true,
    includeIfNull: true,
  )


  final WatchApprovalWhyPhoneEnum? whyPhone;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;



  @JsonKey(
    
    name: r'link',
    required: true,
    includeIfNull: false,
  )


  final String link;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchApproval &&
      other.id == id &&
      other.runId == runId &&
      other.botId == botId &&
      other.bot == bot &&
      other.botAvatar == botAvatar &&
      other.status == status &&
      other.title == title &&
      other.details == details &&
      other.risk == risk &&
      other.payment == payment &&
      other.canAllow == canAllow &&
      other.whyPhone == whyPhone &&
      other.createdAt == createdAt &&
      other.expiresAt == expiresAt &&
      other.link == link;

    @override
    int get hashCode =>
        id.hashCode +
        runId.hashCode +
        botId.hashCode +
        bot.hashCode +
        botAvatar.hashCode +
        status.hashCode +
        title.hashCode +
        details.hashCode +
        risk.hashCode +
        payment.hashCode +
        canAllow.hashCode +
        (whyPhone == null ? 0 : whyPhone.hashCode) +
        createdAt.hashCode +
        expiresAt.hashCode +
        link.hashCode;

  factory WatchApproval.fromJson(Map<String, dynamic> json) => _$WatchApprovalFromJson(json);

  Map<String, dynamic> toJson() => _$WatchApprovalToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum WatchApprovalStatusEnum {
@JsonValue(r'pending')
pending(r'pending'),
@JsonValue(r'approved')
approved(r'approved'),
@JsonValue(r'denied')
denied(r'denied'),
@JsonValue(r'expired')
expired(r'expired');

const WatchApprovalStatusEnum(this.value);

final String value;

@override
String toString() => value;
}



enum WatchApprovalCanAllowEnum {
@JsonValue(r'tap')
tap(r'tap'),
@JsonValue(r'hold')
hold(r'hold'),
@JsonValue(r'phone')
phone(r'phone');

const WatchApprovalCanAllowEnum(this.value);

final String value;

@override
String toString() => value;
}



enum WatchApprovalWhyPhoneEnum {
@JsonValue(r'high_risk')
highRisk(r'high_risk'),
@JsonValue(r'payment')
payment(r'payment'),
@JsonValue(r'setting')
setting(r'setting'),
@JsonValue(r'workspace')
workspace(r'workspace'),
@JsonValue(r'not_yours')
notYours(r'not_yours');

const WatchApprovalWhyPhoneEnum(this.value);

final String value;

@override
String toString() => value;
}



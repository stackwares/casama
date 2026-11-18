// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_approval.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchApprovalCWProxy {
  WatchApproval id(String id);

  WatchApproval runId(String runId);

  WatchApproval botId(String botId);

  WatchApproval bot(String bot);

  WatchApproval botAvatar(String botAvatar);

  WatchApproval status(WatchApprovalStatusEnum status);

  WatchApproval title(String title);

  WatchApproval details(List<String> details);

  WatchApproval risk(WatchRisk risk);

  WatchApproval payment(bool payment);

  WatchApproval canAllow(WatchApprovalCanAllowEnum canAllow);

  WatchApproval whyPhone(WatchApprovalWhyPhoneEnum? whyPhone);

  WatchApproval createdAt(DateTime createdAt);

  WatchApproval expiresAt(DateTime expiresAt);

  WatchApproval link(String link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchApproval(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchApproval(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchApproval call({
    String id,
    String runId,
    String botId,
    String bot,
    String botAvatar,
    WatchApprovalStatusEnum status,
    String title,
    List<String> details,
    WatchRisk risk,
    bool payment,
    WatchApprovalCanAllowEnum canAllow,
    WatchApprovalWhyPhoneEnum? whyPhone,
    DateTime createdAt,
    DateTime expiresAt,
    String link,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchApproval.copyWith(...)` or call `instanceOfWatchApproval.copyWith.fieldName(value)` for a single field.
class _$WatchApprovalCWProxyImpl implements _$WatchApprovalCWProxy {
  const _$WatchApprovalCWProxyImpl(this._value);

  final WatchApproval _value;

  @override
  WatchApproval id(String id) => call(id: id);

  @override
  WatchApproval runId(String runId) => call(runId: runId);

  @override
  WatchApproval botId(String botId) => call(botId: botId);

  @override
  WatchApproval bot(String bot) => call(bot: bot);

  @override
  WatchApproval botAvatar(String botAvatar) => call(botAvatar: botAvatar);

  @override
  WatchApproval status(WatchApprovalStatusEnum status) => call(status: status);

  @override
  WatchApproval title(String title) => call(title: title);

  @override
  WatchApproval details(List<String> details) => call(details: details);

  @override
  WatchApproval risk(WatchRisk risk) => call(risk: risk);

  @override
  WatchApproval payment(bool payment) => call(payment: payment);

  @override
  WatchApproval canAllow(WatchApprovalCanAllowEnum canAllow) =>
      call(canAllow: canAllow);

  @override
  WatchApproval whyPhone(WatchApprovalWhyPhoneEnum? whyPhone) =>
      call(whyPhone: whyPhone);

  @override
  WatchApproval createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  WatchApproval expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  @override
  WatchApproval link(String link) => call(link: link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchApproval(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchApproval(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchApproval call({
    Object? id = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? bot = const $CopyWithPlaceholder(),
    Object? botAvatar = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? details = const $CopyWithPlaceholder(),
    Object? risk = const $CopyWithPlaceholder(),
    Object? payment = const $CopyWithPlaceholder(),
    Object? canAllow = const $CopyWithPlaceholder(),
    Object? whyPhone = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? link = const $CopyWithPlaceholder(),
  }) {
    return WatchApproval(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      runId: runId == const $CopyWithPlaceholder() || runId == null
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      bot: bot == const $CopyWithPlaceholder() || bot == null
          ? _value.bot
          // ignore: cast_nullable_to_non_nullable
          : bot as String,
      botAvatar: botAvatar == const $CopyWithPlaceholder() || botAvatar == null
          ? _value.botAvatar
          // ignore: cast_nullable_to_non_nullable
          : botAvatar as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as WatchApprovalStatusEnum,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      details: details == const $CopyWithPlaceholder() || details == null
          ? _value.details
          // ignore: cast_nullable_to_non_nullable
          : details as List<String>,
      risk: risk == const $CopyWithPlaceholder() || risk == null
          ? _value.risk
          // ignore: cast_nullable_to_non_nullable
          : risk as WatchRisk,
      payment: payment == const $CopyWithPlaceholder() || payment == null
          ? _value.payment
          // ignore: cast_nullable_to_non_nullable
          : payment as bool,
      canAllow: canAllow == const $CopyWithPlaceholder() || canAllow == null
          ? _value.canAllow
          // ignore: cast_nullable_to_non_nullable
          : canAllow as WatchApprovalCanAllowEnum,
      whyPhone: whyPhone == const $CopyWithPlaceholder()
          ? _value.whyPhone
          // ignore: cast_nullable_to_non_nullable
          : whyPhone as WatchApprovalWhyPhoneEnum?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
      link: link == const $CopyWithPlaceholder() || link == null
          ? _value.link
          // ignore: cast_nullable_to_non_nullable
          : link as String,
    );
  }
}

extension $WatchApprovalCopyWith on WatchApproval {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchApproval.copyWith(...)` or `instanceOfWatchApproval.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchApprovalCWProxy get copyWith => _$WatchApprovalCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchApproval _$WatchApprovalFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'WatchApproval',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'run_id',
            'bot_id',
            'bot',
            'bot_avatar',
            'status',
            'title',
            'details',
            'risk',
            'payment',
            'can_allow',
            'why_phone',
            'created_at',
            'expires_at',
            'link',
          ],
        );
        final val = WatchApproval(
          id: $checkedConvert('id', (v) => v as String),
          runId: $checkedConvert('run_id', (v) => v as String),
          botId: $checkedConvert('bot_id', (v) => v as String),
          bot: $checkedConvert('bot', (v) => v as String),
          botAvatar: $checkedConvert('bot_avatar', (v) => v as String),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$WatchApprovalStatusEnumEnumMap, v),
          ),
          title: $checkedConvert('title', (v) => v as String),
          details: $checkedConvert(
            'details',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          risk: $checkedConvert(
            'risk',
            (v) => $enumDecode(_$WatchRiskEnumMap, v),
          ),
          payment: $checkedConvert('payment', (v) => v as bool),
          canAllow: $checkedConvert(
            'can_allow',
            (v) => $enumDecode(_$WatchApprovalCanAllowEnumEnumMap, v),
          ),
          whyPhone: $checkedConvert(
            'why_phone',
            (v) => $enumDecodeNullable(_$WatchApprovalWhyPhoneEnumEnumMap, v),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          expiresAt: $checkedConvert(
            'expires_at',
            (v) => DateTime.parse(v as String),
          ),
          link: $checkedConvert('link', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'runId': 'run_id',
        'botId': 'bot_id',
        'botAvatar': 'bot_avatar',
        'canAllow': 'can_allow',
        'whyPhone': 'why_phone',
        'createdAt': 'created_at',
        'expiresAt': 'expires_at',
      },
    );

Map<String, dynamic> _$WatchApprovalToJson(WatchApproval instance) =>
    <String, dynamic>{
      'id': instance.id,
      'run_id': instance.runId,
      'bot_id': instance.botId,
      'bot': instance.bot,
      'bot_avatar': instance.botAvatar,
      'status': _$WatchApprovalStatusEnumEnumMap[instance.status]!,
      'title': instance.title,
      'details': instance.details,
      'risk': _$WatchRiskEnumMap[instance.risk]!,
      'payment': instance.payment,
      'can_allow': _$WatchApprovalCanAllowEnumEnumMap[instance.canAllow]!,
      'why_phone': _$WatchApprovalWhyPhoneEnumEnumMap[instance.whyPhone],
      'created_at': instance.createdAt.toIso8601String(),
      'expires_at': instance.expiresAt.toIso8601String(),
      'link': instance.link,
    };

const _$WatchApprovalStatusEnumEnumMap = {
  WatchApprovalStatusEnum.pending: 'pending',
  WatchApprovalStatusEnum.approved: 'approved',
  WatchApprovalStatusEnum.denied: 'denied',
  WatchApprovalStatusEnum.expired: 'expired',
};

const _$WatchRiskEnumMap = {
  WatchRisk.low: 'low',
  WatchRisk.medium: 'medium',
  WatchRisk.high: 'high',
};

const _$WatchApprovalCanAllowEnumEnumMap = {
  WatchApprovalCanAllowEnum.tap: 'tap',
  WatchApprovalCanAllowEnum.hold: 'hold',
  WatchApprovalCanAllowEnum.phone: 'phone',
};

const _$WatchApprovalWhyPhoneEnumEnumMap = {
  WatchApprovalWhyPhoneEnum.highRisk: 'high_risk',
  WatchApprovalWhyPhoneEnum.payment: 'payment',
  WatchApprovalWhyPhoneEnum.setting: 'setting',
  WatchApprovalWhyPhoneEnum.workspace: 'workspace',
  WatchApprovalWhyPhoneEnum.notYours: 'not_yours',
};

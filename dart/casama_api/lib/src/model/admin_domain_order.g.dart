// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_domain_order.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminDomainOrderCWProxy {
  AdminDomainOrder id(String id);

  AdminDomainOrder kind(String kind);

  AdminDomainOrder name(String name);

  AdminDomainOrder priceUsd(num priceUsd);

  AdminDomainOrder status(String status);

  AdminDomainOrder failure(String? failure);

  AdminDomainOrder needsApproval(bool needsApproval);

  AdminDomainOrder domainId(String? domainId);

  AdminDomainOrder createdAt(DateTime createdAt);

  AdminDomainOrder paidAt(DateTime? paidAt);

  AdminDomainOrder refundedAt(DateTime? refundedAt);

  AdminDomainOrder orgId(String? orgId);

  AdminDomainOrder orgName(String? orgName);

  AdminDomainOrder attempts(int attempts);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminDomainOrder(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminDomainOrder(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminDomainOrder call({
    String id,
    String kind,
    String name,
    num priceUsd,
    String status,
    String? failure,
    bool needsApproval,
    String? domainId,
    DateTime createdAt,
    DateTime? paidAt,
    DateTime? refundedAt,
    String? orgId,
    String? orgName,
    int attempts,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminDomainOrder.copyWith(...)` or call `instanceOfAdminDomainOrder.copyWith.fieldName(value)` for a single field.
class _$AdminDomainOrderCWProxyImpl implements _$AdminDomainOrderCWProxy {
  const _$AdminDomainOrderCWProxyImpl(this._value);

  final AdminDomainOrder _value;

  @override
  AdminDomainOrder id(String id) => call(id: id);

  @override
  AdminDomainOrder kind(String kind) => call(kind: kind);

  @override
  AdminDomainOrder name(String name) => call(name: name);

  @override
  AdminDomainOrder priceUsd(num priceUsd) => call(priceUsd: priceUsd);

  @override
  AdminDomainOrder status(String status) => call(status: status);

  @override
  AdminDomainOrder failure(String? failure) => call(failure: failure);

  @override
  AdminDomainOrder needsApproval(bool needsApproval) =>
      call(needsApproval: needsApproval);

  @override
  AdminDomainOrder domainId(String? domainId) => call(domainId: domainId);

  @override
  AdminDomainOrder createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  AdminDomainOrder paidAt(DateTime? paidAt) => call(paidAt: paidAt);

  @override
  AdminDomainOrder refundedAt(DateTime? refundedAt) =>
      call(refundedAt: refundedAt);

  @override
  AdminDomainOrder orgId(String? orgId) => call(orgId: orgId);

  @override
  AdminDomainOrder orgName(String? orgName) => call(orgName: orgName);

  @override
  AdminDomainOrder attempts(int attempts) => call(attempts: attempts);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminDomainOrder(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminDomainOrder(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminDomainOrder call({
    Object? id = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? priceUsd = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? failure = const $CopyWithPlaceholder(),
    Object? needsApproval = const $CopyWithPlaceholder(),
    Object? domainId = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? paidAt = const $CopyWithPlaceholder(),
    Object? refundedAt = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? orgName = const $CopyWithPlaceholder(),
    Object? attempts = const $CopyWithPlaceholder(),
  }) {
    return AdminDomainOrder(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      priceUsd: priceUsd == const $CopyWithPlaceholder() || priceUsd == null
          ? _value.priceUsd
          // ignore: cast_nullable_to_non_nullable
          : priceUsd as num,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as String,
      failure: failure == const $CopyWithPlaceholder()
          ? _value.failure
          // ignore: cast_nullable_to_non_nullable
          : failure as String?,
      needsApproval:
          needsApproval == const $CopyWithPlaceholder() || needsApproval == null
          ? _value.needsApproval
          // ignore: cast_nullable_to_non_nullable
          : needsApproval as bool,
      domainId: domainId == const $CopyWithPlaceholder()
          ? _value.domainId
          // ignore: cast_nullable_to_non_nullable
          : domainId as String?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      paidAt: paidAt == const $CopyWithPlaceholder()
          ? _value.paidAt
          // ignore: cast_nullable_to_non_nullable
          : paidAt as DateTime?,
      refundedAt: refundedAt == const $CopyWithPlaceholder()
          ? _value.refundedAt
          // ignore: cast_nullable_to_non_nullable
          : refundedAt as DateTime?,
      orgId: orgId == const $CopyWithPlaceholder()
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String?,
      orgName: orgName == const $CopyWithPlaceholder()
          ? _value.orgName
          // ignore: cast_nullable_to_non_nullable
          : orgName as String?,
      attempts: attempts == const $CopyWithPlaceholder() || attempts == null
          ? _value.attempts
          // ignore: cast_nullable_to_non_nullable
          : attempts as int,
    );
  }
}

extension $AdminDomainOrderCopyWith on AdminDomainOrder {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminDomainOrder.copyWith(...)` or `instanceOfAdminDomainOrder.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminDomainOrderCWProxy get copyWith => _$AdminDomainOrderCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminDomainOrder _$AdminDomainOrderFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminDomainOrder',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'kind',
            'name',
            'price_usd',
            'status',
            'failure',
            'needs_approval',
            'domain_id',
            'created_at',
            'paid_at',
            'refunded_at',
            'org_id',
            'org_name',
            'attempts',
          ],
        );
        final val = AdminDomainOrder(
          id: $checkedConvert('id', (v) => v as String),
          kind: $checkedConvert('kind', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          priceUsd: $checkedConvert('price_usd', (v) => v as num),
          status: $checkedConvert('status', (v) => v as String),
          failure: $checkedConvert('failure', (v) => v as String?),
          needsApproval: $checkedConvert('needs_approval', (v) => v as bool),
          domainId: $checkedConvert('domain_id', (v) => v as String?),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          paidAt: $checkedConvert(
            'paid_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          refundedAt: $checkedConvert(
            'refunded_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          orgId: $checkedConvert('org_id', (v) => v as String?),
          orgName: $checkedConvert('org_name', (v) => v as String?),
          attempts: $checkedConvert('attempts', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'priceUsd': 'price_usd',
        'needsApproval': 'needs_approval',
        'domainId': 'domain_id',
        'createdAt': 'created_at',
        'paidAt': 'paid_at',
        'refundedAt': 'refunded_at',
        'orgId': 'org_id',
        'orgName': 'org_name',
      },
    );

Map<String, dynamic> _$AdminDomainOrderToJson(AdminDomainOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': instance.kind,
      'name': instance.name,
      'price_usd': instance.priceUsd,
      'status': instance.status,
      'failure': instance.failure,
      'needs_approval': instance.needsApproval,
      'domain_id': instance.domainId,
      'created_at': instance.createdAt.toIso8601String(),
      'paid_at': instance.paidAt?.toIso8601String(),
      'refunded_at': instance.refundedAt?.toIso8601String(),
      'org_id': instance.orgId,
      'org_name': instance.orgName,
      'attempts': instance.attempts,
    };

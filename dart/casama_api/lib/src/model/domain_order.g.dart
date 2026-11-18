// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain_order.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DomainOrderCWProxy {
  DomainOrder id(String id);

  DomainOrder kind(String kind);

  DomainOrder name(String name);

  DomainOrder priceUsd(num priceUsd);

  DomainOrder status(String status);

  DomainOrder failure(String? failure);

  DomainOrder needsApproval(bool needsApproval);

  DomainOrder domainId(String? domainId);

  DomainOrder createdAt(DateTime createdAt);

  DomainOrder paidAt(DateTime? paidAt);

  DomainOrder refundedAt(DateTime? refundedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DomainOrder(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DomainOrder(...).copyWith(id: 12, name: "My name")
  /// ```
  DomainOrder call({
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
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDomainOrder.copyWith(...)` or call `instanceOfDomainOrder.copyWith.fieldName(value)` for a single field.
class _$DomainOrderCWProxyImpl implements _$DomainOrderCWProxy {
  const _$DomainOrderCWProxyImpl(this._value);

  final DomainOrder _value;

  @override
  DomainOrder id(String id) => call(id: id);

  @override
  DomainOrder kind(String kind) => call(kind: kind);

  @override
  DomainOrder name(String name) => call(name: name);

  @override
  DomainOrder priceUsd(num priceUsd) => call(priceUsd: priceUsd);

  @override
  DomainOrder status(String status) => call(status: status);

  @override
  DomainOrder failure(String? failure) => call(failure: failure);

  @override
  DomainOrder needsApproval(bool needsApproval) =>
      call(needsApproval: needsApproval);

  @override
  DomainOrder domainId(String? domainId) => call(domainId: domainId);

  @override
  DomainOrder createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  DomainOrder paidAt(DateTime? paidAt) => call(paidAt: paidAt);

  @override
  DomainOrder refundedAt(DateTime? refundedAt) => call(refundedAt: refundedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DomainOrder(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DomainOrder(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DomainOrder call({
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
  }) {
    return DomainOrder(
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
    );
  }
}

extension $DomainOrderCopyWith on DomainOrder {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDomainOrder.copyWith(...)` or `instanceOfDomainOrder.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DomainOrderCWProxy get copyWith => _$DomainOrderCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DomainOrder _$DomainOrderFromJson(Map<String, dynamic> json) => $checkedCreate(
  'DomainOrder',
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
      ],
    );
    final val = DomainOrder(
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
  },
);

Map<String, dynamic> _$DomainOrderToJson(DomainOrder instance) =>
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
    };

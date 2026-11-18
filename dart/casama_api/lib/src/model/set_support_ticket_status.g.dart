// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_support_ticket_status.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetSupportTicketStatusCWProxy {
  SetSupportTicketStatus status(SetSupportTicketStatusStatusEnum status);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetSupportTicketStatus(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetSupportTicketStatus(...).copyWith(id: 12, name: "My name")
  /// ```
  SetSupportTicketStatus call({SetSupportTicketStatusStatusEnum status});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetSupportTicketStatus.copyWith(...)` or call `instanceOfSetSupportTicketStatus.copyWith.fieldName(value)` for a single field.
class _$SetSupportTicketStatusCWProxyImpl
    implements _$SetSupportTicketStatusCWProxy {
  const _$SetSupportTicketStatusCWProxyImpl(this._value);

  final SetSupportTicketStatus _value;

  @override
  SetSupportTicketStatus status(SetSupportTicketStatusStatusEnum status) =>
      call(status: status);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetSupportTicketStatus(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetSupportTicketStatus(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetSupportTicketStatus call({Object? status = const $CopyWithPlaceholder()}) {
    return SetSupportTicketStatus(
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as SetSupportTicketStatusStatusEnum,
    );
  }
}

extension $SetSupportTicketStatusCopyWith on SetSupportTicketStatus {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetSupportTicketStatus.copyWith(...)` or `instanceOfSetSupportTicketStatus.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetSupportTicketStatusCWProxy get copyWith =>
      _$SetSupportTicketStatusCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetSupportTicketStatus _$SetSupportTicketStatusFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SetSupportTicketStatus', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['status']);
  final val = SetSupportTicketStatus(
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$SetSupportTicketStatusStatusEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$SetSupportTicketStatusToJson(
  SetSupportTicketStatus instance,
) => <String, dynamic>{
  'status': _$SetSupportTicketStatusStatusEnumEnumMap[instance.status]!,
};

const _$SetSupportTicketStatusStatusEnumEnumMap = {
  SetSupportTicketStatusStatusEnum.open: 'open',
  SetSupportTicketStatusStatusEnum.closed: 'closed',
};

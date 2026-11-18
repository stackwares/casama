// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_entry.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreditEntryCWProxy {
  CreditEntry delta(num delta);

  CreditEntry reason(String reason);

  CreditEntry note(String? note);

  CreditEntry balanceAfter(num balanceAfter);

  CreditEntry createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreditEntry(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreditEntry(...).copyWith(id: 12, name: "My name")
  /// ```
  CreditEntry call({
    num delta,
    String reason,
    String? note,
    num balanceAfter,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreditEntry.copyWith(...)` or call `instanceOfCreditEntry.copyWith.fieldName(value)` for a single field.
class _$CreditEntryCWProxyImpl implements _$CreditEntryCWProxy {
  const _$CreditEntryCWProxyImpl(this._value);

  final CreditEntry _value;

  @override
  CreditEntry delta(num delta) => call(delta: delta);

  @override
  CreditEntry reason(String reason) => call(reason: reason);

  @override
  CreditEntry note(String? note) => call(note: note);

  @override
  CreditEntry balanceAfter(num balanceAfter) =>
      call(balanceAfter: balanceAfter);

  @override
  CreditEntry createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreditEntry(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreditEntry(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreditEntry call({
    Object? delta = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? balanceAfter = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return CreditEntry(
      delta: delta == const $CopyWithPlaceholder() || delta == null
          ? _value.delta
          // ignore: cast_nullable_to_non_nullable
          : delta as num,
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
      balanceAfter:
          balanceAfter == const $CopyWithPlaceholder() || balanceAfter == null
          ? _value.balanceAfter
          // ignore: cast_nullable_to_non_nullable
          : balanceAfter as num,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $CreditEntryCopyWith on CreditEntry {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreditEntry.copyWith(...)` or `instanceOfCreditEntry.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreditEntryCWProxy get copyWith => _$CreditEntryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreditEntry _$CreditEntryFromJson(Map<String, dynamic> json) => $checkedCreate(
  'CreditEntry',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'delta',
        'reason',
        'note',
        'balance_after',
        'created_at',
      ],
    );
    final val = CreditEntry(
      delta: $checkedConvert('delta', (v) => v as num),
      reason: $checkedConvert('reason', (v) => v as String),
      note: $checkedConvert('note', (v) => v as String?),
      balanceAfter: $checkedConvert('balance_after', (v) => v as num),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'balanceAfter': 'balance_after',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$CreditEntryToJson(CreditEntry instance) =>
    <String, dynamic>{
      'delta': instance.delta,
      'reason': instance.reason,
      'note': instance.note,
      'balance_after': instance.balanceAfter,
      'created_at': instance.createdAt.toIso8601String(),
    };

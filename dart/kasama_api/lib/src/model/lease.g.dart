// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lease.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LeaseCWProxy {
  Lease computerId(String computerId);

  Lease holderType(LeaseHolderTypeEnum holderType);

  Lease holderId(String? holderId);

  Lease mode(LeaseModeEnum mode);

  Lease expiresAt(DateTime? expiresAt);

  Lease you(bool you);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Lease(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Lease(...).copyWith(id: 12, name: "My name")
  /// ```
  Lease call({
    String computerId,
    LeaseHolderTypeEnum holderType,
    String? holderId,
    LeaseModeEnum mode,
    DateTime? expiresAt,
    bool you,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLease.copyWith(...)` or call `instanceOfLease.copyWith.fieldName(value)` for a single field.
class _$LeaseCWProxyImpl implements _$LeaseCWProxy {
  const _$LeaseCWProxyImpl(this._value);

  final Lease _value;

  @override
  Lease computerId(String computerId) => call(computerId: computerId);

  @override
  Lease holderType(LeaseHolderTypeEnum holderType) =>
      call(holderType: holderType);

  @override
  Lease holderId(String? holderId) => call(holderId: holderId);

  @override
  Lease mode(LeaseModeEnum mode) => call(mode: mode);

  @override
  Lease expiresAt(DateTime? expiresAt) => call(expiresAt: expiresAt);

  @override
  Lease you(bool you) => call(you: you);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Lease(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Lease(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Lease call({
    Object? computerId = const $CopyWithPlaceholder(),
    Object? holderType = const $CopyWithPlaceholder(),
    Object? holderId = const $CopyWithPlaceholder(),
    Object? mode = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? you = const $CopyWithPlaceholder(),
  }) {
    return Lease(
      computerId:
          computerId == const $CopyWithPlaceholder() || computerId == null
          ? _value.computerId
          // ignore: cast_nullable_to_non_nullable
          : computerId as String,
      holderType:
          holderType == const $CopyWithPlaceholder() || holderType == null
          ? _value.holderType
          // ignore: cast_nullable_to_non_nullable
          : holderType as LeaseHolderTypeEnum,
      holderId: holderId == const $CopyWithPlaceholder()
          ? _value.holderId
          // ignore: cast_nullable_to_non_nullable
          : holderId as String?,
      mode: mode == const $CopyWithPlaceholder() || mode == null
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as LeaseModeEnum,
      expiresAt: expiresAt == const $CopyWithPlaceholder()
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime?,
      you: you == const $CopyWithPlaceholder() || you == null
          ? _value.you
          // ignore: cast_nullable_to_non_nullable
          : you as bool,
    );
  }
}

extension $LeaseCopyWith on Lease {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLease.copyWith(...)` or `instanceOfLease.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LeaseCWProxy get copyWith => _$LeaseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Lease _$LeaseFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Lease',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'computer_id',
        'holder_type',
        'holder_id',
        'mode',
        'expires_at',
        'you',
      ],
    );
    final val = Lease(
      computerId: $checkedConvert('computer_id', (v) => v as String),
      holderType: $checkedConvert(
        'holder_type',
        (v) => $enumDecode(_$LeaseHolderTypeEnumEnumMap, v),
      ),
      holderId: $checkedConvert('holder_id', (v) => v as String?),
      mode: $checkedConvert(
        'mode',
        (v) => $enumDecode(_$LeaseModeEnumEnumMap, v),
      ),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      you: $checkedConvert('you', (v) => v as bool),
    );
    return val;
  },
  fieldKeyMap: const {
    'computerId': 'computer_id',
    'holderType': 'holder_type',
    'holderId': 'holder_id',
    'expiresAt': 'expires_at',
  },
);

Map<String, dynamic> _$LeaseToJson(Lease instance) => <String, dynamic>{
  'computer_id': instance.computerId,
  'holder_type': _$LeaseHolderTypeEnumEnumMap[instance.holderType]!,
  'holder_id': instance.holderId,
  'mode': _$LeaseModeEnumEnumMap[instance.mode]!,
  'expires_at': instance.expiresAt?.toIso8601String(),
  'you': instance.you,
};

const _$LeaseHolderTypeEnumEnumMap = {
  LeaseHolderTypeEnum.bot: 'bot',
  LeaseHolderTypeEnum.user: 'user',
};

const _$LeaseModeEnumEnumMap = {
  LeaseModeEnum.view: 'view',
  LeaseModeEnum.control: 'control',
};

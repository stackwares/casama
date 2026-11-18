// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'encryption_status.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EncryptionStatusCWProxy {
  EncryptionStatus mode(EncryptionStatusModeEnum mode);

  EncryptionStatus available(bool available);

  EncryptionStatus key(EncryptionStatusKeyEnum? key);

  EncryptionStatus since(DateTime? since);

  EncryptionStatus rotatedAt(DateTime? rotatedAt);

  EncryptionStatus rekeying(bool? rekeying);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EncryptionStatus(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EncryptionStatus(...).copyWith(id: 12, name: "My name")
  /// ```
  EncryptionStatus call({
    EncryptionStatusModeEnum mode,
    bool available,
    EncryptionStatusKeyEnum? key,
    DateTime? since,
    DateTime? rotatedAt,
    bool? rekeying,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfEncryptionStatus.copyWith(...)` or call `instanceOfEncryptionStatus.copyWith.fieldName(value)` for a single field.
class _$EncryptionStatusCWProxyImpl implements _$EncryptionStatusCWProxy {
  const _$EncryptionStatusCWProxyImpl(this._value);

  final EncryptionStatus _value;

  @override
  EncryptionStatus mode(EncryptionStatusModeEnum mode) => call(mode: mode);

  @override
  EncryptionStatus available(bool available) => call(available: available);

  @override
  EncryptionStatus key(EncryptionStatusKeyEnum? key) => call(key: key);

  @override
  EncryptionStatus since(DateTime? since) => call(since: since);

  @override
  EncryptionStatus rotatedAt(DateTime? rotatedAt) => call(rotatedAt: rotatedAt);

  @override
  EncryptionStatus rekeying(bool? rekeying) => call(rekeying: rekeying);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EncryptionStatus(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EncryptionStatus(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  EncryptionStatus call({
    Object? mode = const $CopyWithPlaceholder(),
    Object? available = const $CopyWithPlaceholder(),
    Object? key = const $CopyWithPlaceholder(),
    Object? since = const $CopyWithPlaceholder(),
    Object? rotatedAt = const $CopyWithPlaceholder(),
    Object? rekeying = const $CopyWithPlaceholder(),
  }) {
    return EncryptionStatus(
      mode: mode == const $CopyWithPlaceholder() || mode == null
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as EncryptionStatusModeEnum,
      available: available == const $CopyWithPlaceholder() || available == null
          ? _value.available
          // ignore: cast_nullable_to_non_nullable
          : available as bool,
      key: key == const $CopyWithPlaceholder()
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as EncryptionStatusKeyEnum?,
      since: since == const $CopyWithPlaceholder()
          ? _value.since
          // ignore: cast_nullable_to_non_nullable
          : since as DateTime?,
      rotatedAt: rotatedAt == const $CopyWithPlaceholder()
          ? _value.rotatedAt
          // ignore: cast_nullable_to_non_nullable
          : rotatedAt as DateTime?,
      rekeying: rekeying == const $CopyWithPlaceholder()
          ? _value.rekeying
          // ignore: cast_nullable_to_non_nullable
          : rekeying as bool?,
    );
  }
}

extension $EncryptionStatusCopyWith on EncryptionStatus {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfEncryptionStatus.copyWith(...)` or `instanceOfEncryptionStatus.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EncryptionStatusCWProxy get copyWith => _$EncryptionStatusCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EncryptionStatus _$EncryptionStatusFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EncryptionStatus', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['mode', 'available', 'key', 'since', 'rotated_at'],
      );
      final val = EncryptionStatus(
        mode: $checkedConvert(
          'mode',
          (v) => $enumDecode(_$EncryptionStatusModeEnumEnumMap, v),
        ),
        available: $checkedConvert('available', (v) => v as bool),
        key: $checkedConvert(
          'key',
          (v) => $enumDecodeNullable(_$EncryptionStatusKeyEnumEnumMap, v),
        ),
        since: $checkedConvert(
          'since',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        rotatedAt: $checkedConvert(
          'rotated_at',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        rekeying: $checkedConvert('rekeying', (v) => v as bool?),
      );
      return val;
    }, fieldKeyMap: const {'rotatedAt': 'rotated_at'});

Map<String, dynamic> _$EncryptionStatusToJson(EncryptionStatus instance) =>
    <String, dynamic>{
      'mode': _$EncryptionStatusModeEnumEnumMap[instance.mode]!,
      'available': instance.available,
      'key': _$EncryptionStatusKeyEnumEnumMap[instance.key],
      'since': instance.since?.toIso8601String(),
      'rotated_at': instance.rotatedAt?.toIso8601String(),
      'rekeying': ?instance.rekeying,
    };

const _$EncryptionStatusModeEnumEnumMap = {
  EncryptionStatusModeEnum.off: 'off',
  EncryptionStatusModeEnum.encrypting: 'encrypting',
  EncryptionStatusModeEnum.on_: 'on',
  EncryptionStatusModeEnum.decrypting: 'decrypting',
};

const _$EncryptionStatusKeyEnumEnumMap = {
  EncryptionStatusKeyEnum.serverKey: 'server_key',
  EncryptionStatusKeyEnum.awsKms: 'aws_kms',
};

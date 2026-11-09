// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UsageEventPayloadCWProxy {
  UsageEventPayload tokensIn(int tokensIn);

  UsageEventPayload tokensOut(int tokensOut);

  UsageEventPayload costUsd(num costUsd);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UsageEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UsageEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  UsageEventPayload call({int tokensIn, int tokensOut, num costUsd});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfUsageEventPayload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfUsageEventPayload.copyWith.fieldName(...)`
class _$UsageEventPayloadCWProxyImpl implements _$UsageEventPayloadCWProxy {
  const _$UsageEventPayloadCWProxyImpl(this._value);

  final UsageEventPayload _value;

  @override
  UsageEventPayload tokensIn(int tokensIn) => this(tokensIn: tokensIn);

  @override
  UsageEventPayload tokensOut(int tokensOut) => this(tokensOut: tokensOut);

  @override
  UsageEventPayload costUsd(num costUsd) => this(costUsd: costUsd);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UsageEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UsageEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  UsageEventPayload call({
    Object? tokensIn = const $CopyWithPlaceholder(),
    Object? tokensOut = const $CopyWithPlaceholder(),
    Object? costUsd = const $CopyWithPlaceholder(),
  }) {
    return UsageEventPayload(
      tokensIn: tokensIn == const $CopyWithPlaceholder()
          ? _value.tokensIn
          // ignore: cast_nullable_to_non_nullable
          : tokensIn as int,
      tokensOut: tokensOut == const $CopyWithPlaceholder()
          ? _value.tokensOut
          // ignore: cast_nullable_to_non_nullable
          : tokensOut as int,
      costUsd: costUsd == const $CopyWithPlaceholder()
          ? _value.costUsd
          // ignore: cast_nullable_to_non_nullable
          : costUsd as num,
    );
  }
}

extension $UsageEventPayloadCopyWith on UsageEventPayload {
  /// Returns a callable class that can be used as follows: `instanceOfUsageEventPayload.copyWith(...)` or like so:`instanceOfUsageEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UsageEventPayloadCWProxy get copyWith =>
      _$UsageEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsageEventPayload _$UsageEventPayloadFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'UsageEventPayload',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['tokens_in', 'tokens_out', 'cost_usd'],
        );
        final val = UsageEventPayload(
          tokensIn: $checkedConvert('tokens_in', (v) => (v as num).toInt()),
          tokensOut: $checkedConvert('tokens_out', (v) => (v as num).toInt()),
          costUsd: $checkedConvert('cost_usd', (v) => v as num),
        );
        return val;
      },
      fieldKeyMap: const {
        'tokensIn': 'tokens_in',
        'tokensOut': 'tokens_out',
        'costUsd': 'cost_usd',
      },
    );

Map<String, dynamic> _$UsageEventPayloadToJson(UsageEventPayload instance) =>
    <String, dynamic>{
      'tokens_in': instance.tokensIn,
      'tokens_out': instance.tokensOut,
      'cost_usd': instance.costUsd,
    };

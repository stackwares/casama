// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UsageEventPayloadCWProxy {
  UsageEventPayload tokensIn(int tokensIn);

  UsageEventPayload tokensOut(int tokensOut);

  UsageEventPayload costUsd(num costUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UsageEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UsageEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  UsageEventPayload call({int tokensIn, int tokensOut, num costUsd});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUsageEventPayload.copyWith(...)` or call `instanceOfUsageEventPayload.copyWith.fieldName(value)` for a single field.
class _$UsageEventPayloadCWProxyImpl implements _$UsageEventPayloadCWProxy {
  const _$UsageEventPayloadCWProxyImpl(this._value);

  final UsageEventPayload _value;

  @override
  UsageEventPayload tokensIn(int tokensIn) => call(tokensIn: tokensIn);

  @override
  UsageEventPayload tokensOut(int tokensOut) => call(tokensOut: tokensOut);

  @override
  UsageEventPayload costUsd(num costUsd) => call(costUsd: costUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UsageEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UsageEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UsageEventPayload call({
    Object? tokensIn = const $CopyWithPlaceholder(),
    Object? tokensOut = const $CopyWithPlaceholder(),
    Object? costUsd = const $CopyWithPlaceholder(),
  }) {
    return UsageEventPayload(
      tokensIn: tokensIn == const $CopyWithPlaceholder() || tokensIn == null
          ? _value.tokensIn
          // ignore: cast_nullable_to_non_nullable
          : tokensIn as int,
      tokensOut: tokensOut == const $CopyWithPlaceholder() || tokensOut == null
          ? _value.tokensOut
          // ignore: cast_nullable_to_non_nullable
          : tokensOut as int,
      costUsd: costUsd == const $CopyWithPlaceholder() || costUsd == null
          ? _value.costUsd
          // ignore: cast_nullable_to_non_nullable
          : costUsd as num,
    );
  }
}

extension $UsageEventPayloadCopyWith on UsageEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUsageEventPayload.copyWith(...)` or `instanceOfUsageEventPayload.copyWith.fieldName(...)`.
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

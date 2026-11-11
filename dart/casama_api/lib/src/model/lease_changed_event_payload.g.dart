// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lease_changed_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LeaseChangedEventPayloadCWProxy {
  LeaseChangedEventPayload computerId(String computerId);

  LeaseChangedEventPayload holderType(
    LeaseChangedEventPayloadHolderTypeEnum holderType,
  );

  LeaseChangedEventPayload mode(LeaseChangedEventPayloadModeEnum mode);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LeaseChangedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LeaseChangedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  LeaseChangedEventPayload call({
    String computerId,
    LeaseChangedEventPayloadHolderTypeEnum holderType,
    LeaseChangedEventPayloadModeEnum mode,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLeaseChangedEventPayload.copyWith(...)` or call `instanceOfLeaseChangedEventPayload.copyWith.fieldName(value)` for a single field.
class _$LeaseChangedEventPayloadCWProxyImpl
    implements _$LeaseChangedEventPayloadCWProxy {
  const _$LeaseChangedEventPayloadCWProxyImpl(this._value);

  final LeaseChangedEventPayload _value;

  @override
  LeaseChangedEventPayload computerId(String computerId) =>
      call(computerId: computerId);

  @override
  LeaseChangedEventPayload holderType(
    LeaseChangedEventPayloadHolderTypeEnum holderType,
  ) => call(holderType: holderType);

  @override
  LeaseChangedEventPayload mode(LeaseChangedEventPayloadModeEnum mode) =>
      call(mode: mode);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LeaseChangedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LeaseChangedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LeaseChangedEventPayload call({
    Object? computerId = const $CopyWithPlaceholder(),
    Object? holderType = const $CopyWithPlaceholder(),
    Object? mode = const $CopyWithPlaceholder(),
  }) {
    return LeaseChangedEventPayload(
      computerId:
          computerId == const $CopyWithPlaceholder() || computerId == null
          ? _value.computerId
          // ignore: cast_nullable_to_non_nullable
          : computerId as String,
      holderType:
          holderType == const $CopyWithPlaceholder() || holderType == null
          ? _value.holderType
          // ignore: cast_nullable_to_non_nullable
          : holderType as LeaseChangedEventPayloadHolderTypeEnum,
      mode: mode == const $CopyWithPlaceholder() || mode == null
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as LeaseChangedEventPayloadModeEnum,
    );
  }
}

extension $LeaseChangedEventPayloadCopyWith on LeaseChangedEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLeaseChangedEventPayload.copyWith(...)` or `instanceOfLeaseChangedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LeaseChangedEventPayloadCWProxy get copyWith =>
      _$LeaseChangedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaseChangedEventPayload _$LeaseChangedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'LeaseChangedEventPayload',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['computer_id', 'holder_type', 'mode'],
    );
    final val = LeaseChangedEventPayload(
      computerId: $checkedConvert('computer_id', (v) => v as String),
      holderType: $checkedConvert(
        'holder_type',
        (v) => $enumDecode(_$LeaseChangedEventPayloadHolderTypeEnumEnumMap, v),
      ),
      mode: $checkedConvert(
        'mode',
        (v) => $enumDecode(_$LeaseChangedEventPayloadModeEnumEnumMap, v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'computerId': 'computer_id', 'holderType': 'holder_type'},
);

Map<String, dynamic> _$LeaseChangedEventPayloadToJson(
  LeaseChangedEventPayload instance,
) => <String, dynamic>{
  'computer_id': instance.computerId,
  'holder_type':
      _$LeaseChangedEventPayloadHolderTypeEnumEnumMap[instance.holderType]!,
  'mode': _$LeaseChangedEventPayloadModeEnumEnumMap[instance.mode]!,
};

const _$LeaseChangedEventPayloadHolderTypeEnumEnumMap = {
  LeaseChangedEventPayloadHolderTypeEnum.bot: 'bot',
  LeaseChangedEventPayloadHolderTypeEnum.user: 'user',
};

const _$LeaseChangedEventPayloadModeEnumEnumMap = {
  LeaseChangedEventPayloadModeEnum.view: 'view',
  LeaseChangedEventPayloadModeEnum.control: 'control',
};

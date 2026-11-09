// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_written_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MemoryWrittenEventPayloadCWProxy {
  MemoryWrittenEventPayload memoryId(String memoryId);

  MemoryWrittenEventPayload kind(MemoryWrittenEventPayloadKindEnum kind);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MemoryWrittenEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MemoryWrittenEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  MemoryWrittenEventPayload call({
    String memoryId,
    MemoryWrittenEventPayloadKindEnum kind,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMemoryWrittenEventPayload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMemoryWrittenEventPayload.copyWith.fieldName(...)`
class _$MemoryWrittenEventPayloadCWProxyImpl
    implements _$MemoryWrittenEventPayloadCWProxy {
  const _$MemoryWrittenEventPayloadCWProxyImpl(this._value);

  final MemoryWrittenEventPayload _value;

  @override
  MemoryWrittenEventPayload memoryId(String memoryId) =>
      this(memoryId: memoryId);

  @override
  MemoryWrittenEventPayload kind(MemoryWrittenEventPayloadKindEnum kind) =>
      this(kind: kind);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MemoryWrittenEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MemoryWrittenEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  MemoryWrittenEventPayload call({
    Object? memoryId = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
  }) {
    return MemoryWrittenEventPayload(
      memoryId: memoryId == const $CopyWithPlaceholder()
          ? _value.memoryId
          // ignore: cast_nullable_to_non_nullable
          : memoryId as String,
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as MemoryWrittenEventPayloadKindEnum,
    );
  }
}

extension $MemoryWrittenEventPayloadCopyWith on MemoryWrittenEventPayload {
  /// Returns a callable class that can be used as follows: `instanceOfMemoryWrittenEventPayload.copyWith(...)` or like so:`instanceOfMemoryWrittenEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MemoryWrittenEventPayloadCWProxy get copyWith =>
      _$MemoryWrittenEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemoryWrittenEventPayload _$MemoryWrittenEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('MemoryWrittenEventPayload', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['memory_id', 'kind']);
  final val = MemoryWrittenEventPayload(
    memoryId: $checkedConvert('memory_id', (v) => v as String),
    kind: $checkedConvert(
      'kind',
      (v) => $enumDecode(_$MemoryWrittenEventPayloadKindEnumEnumMap, v),
    ),
  );
  return val;
}, fieldKeyMap: const {'memoryId': 'memory_id'});

Map<String, dynamic> _$MemoryWrittenEventPayloadToJson(
  MemoryWrittenEventPayload instance,
) => <String, dynamic>{
  'memory_id': instance.memoryId,
  'kind': _$MemoryWrittenEventPayloadKindEnumEnumMap[instance.kind]!,
};

const _$MemoryWrittenEventPayloadKindEnumEnumMap = {
  MemoryWrittenEventPayloadKindEnum.fact: 'fact',
  MemoryWrittenEventPayloadKindEnum.episode: 'episode',
  MemoryWrittenEventPayloadKindEnum.summary: 'summary',
  MemoryWrittenEventPayloadKindEnum.preference: 'preference',
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_written_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MemoryWrittenEventPayloadCWProxy {
  MemoryWrittenEventPayload memoryId(String memoryId);

  MemoryWrittenEventPayload kind(MemoryWrittenEventPayloadKindEnum kind);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MemoryWrittenEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MemoryWrittenEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  MemoryWrittenEventPayload call({
    String memoryId,
    MemoryWrittenEventPayloadKindEnum kind,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMemoryWrittenEventPayload.copyWith(...)` or call `instanceOfMemoryWrittenEventPayload.copyWith.fieldName(value)` for a single field.
class _$MemoryWrittenEventPayloadCWProxyImpl
    implements _$MemoryWrittenEventPayloadCWProxy {
  const _$MemoryWrittenEventPayloadCWProxyImpl(this._value);

  final MemoryWrittenEventPayload _value;

  @override
  MemoryWrittenEventPayload memoryId(String memoryId) =>
      call(memoryId: memoryId);

  @override
  MemoryWrittenEventPayload kind(MemoryWrittenEventPayloadKindEnum kind) =>
      call(kind: kind);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MemoryWrittenEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MemoryWrittenEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MemoryWrittenEventPayload call({
    Object? memoryId = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
  }) {
    return MemoryWrittenEventPayload(
      memoryId: memoryId == const $CopyWithPlaceholder() || memoryId == null
          ? _value.memoryId
          // ignore: cast_nullable_to_non_nullable
          : memoryId as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as MemoryWrittenEventPayloadKindEnum,
    );
  }
}

extension $MemoryWrittenEventPayloadCopyWith on MemoryWrittenEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMemoryWrittenEventPayload.copyWith(...)` or `instanceOfMemoryWrittenEventPayload.copyWith.fieldName(...)`.
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

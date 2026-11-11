// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbound_call_transcript_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OutboundCallTranscriptInnerCWProxy {
  OutboundCallTranscriptInner role(OutboundCallTranscriptInnerRoleEnum role);

  OutboundCallTranscriptInner text(String text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OutboundCallTranscriptInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OutboundCallTranscriptInner(...).copyWith(id: 12, name: "My name")
  /// ```
  OutboundCallTranscriptInner call({
    OutboundCallTranscriptInnerRoleEnum role,
    String text,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfOutboundCallTranscriptInner.copyWith(...)` or call `instanceOfOutboundCallTranscriptInner.copyWith.fieldName(value)` for a single field.
class _$OutboundCallTranscriptInnerCWProxyImpl
    implements _$OutboundCallTranscriptInnerCWProxy {
  const _$OutboundCallTranscriptInnerCWProxyImpl(this._value);

  final OutboundCallTranscriptInner _value;

  @override
  OutboundCallTranscriptInner role(OutboundCallTranscriptInnerRoleEnum role) =>
      call(role: role);

  @override
  OutboundCallTranscriptInner text(String text) => call(text: text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OutboundCallTranscriptInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OutboundCallTranscriptInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  OutboundCallTranscriptInner call({
    Object? role = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return OutboundCallTranscriptInner(
      role: role == const $CopyWithPlaceholder() || role == null
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as OutboundCallTranscriptInnerRoleEnum,
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $OutboundCallTranscriptInnerCopyWith on OutboundCallTranscriptInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfOutboundCallTranscriptInner.copyWith(...)` or `instanceOfOutboundCallTranscriptInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OutboundCallTranscriptInnerCWProxy get copyWith =>
      _$OutboundCallTranscriptInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutboundCallTranscriptInner _$OutboundCallTranscriptInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('OutboundCallTranscriptInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['role', 'text']);
  final val = OutboundCallTranscriptInner(
    role: $checkedConvert(
      'role',
      (v) => $enumDecode(_$OutboundCallTranscriptInnerRoleEnumEnumMap, v),
    ),
    text: $checkedConvert('text', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$OutboundCallTranscriptInnerToJson(
  OutboundCallTranscriptInner instance,
) => <String, dynamic>{
  'role': _$OutboundCallTranscriptInnerRoleEnumEnumMap[instance.role]!,
  'text': instance.text,
};

const _$OutboundCallTranscriptInnerRoleEnumEnumMap = {
  OutboundCallTranscriptInnerRoleEnum.bot: 'bot',
  OutboundCallTranscriptInnerRoleEnum.callee: 'callee',
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_template_file_memories_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotTemplateFileMemoriesInnerCWProxy {
  BotTemplateFileMemoriesInner kind(BotTemplateFileMemoriesInnerKindEnum kind);

  BotTemplateFileMemoriesInner content(String content);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotTemplateFileMemoriesInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotTemplateFileMemoriesInner(...).copyWith(id: 12, name: "My name")
  /// ```
  BotTemplateFileMemoriesInner call({
    BotTemplateFileMemoriesInnerKindEnum kind,
    String content,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotTemplateFileMemoriesInner.copyWith(...)` or call `instanceOfBotTemplateFileMemoriesInner.copyWith.fieldName(value)` for a single field.
class _$BotTemplateFileMemoriesInnerCWProxyImpl
    implements _$BotTemplateFileMemoriesInnerCWProxy {
  const _$BotTemplateFileMemoriesInnerCWProxyImpl(this._value);

  final BotTemplateFileMemoriesInner _value;

  @override
  BotTemplateFileMemoriesInner kind(
    BotTemplateFileMemoriesInnerKindEnum kind,
  ) => call(kind: kind);

  @override
  BotTemplateFileMemoriesInner content(String content) =>
      call(content: content);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotTemplateFileMemoriesInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotTemplateFileMemoriesInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotTemplateFileMemoriesInner call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? content = const $CopyWithPlaceholder(),
  }) {
    return BotTemplateFileMemoriesInner(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as BotTemplateFileMemoriesInnerKindEnum,
      content: content == const $CopyWithPlaceholder() || content == null
          ? _value.content
          // ignore: cast_nullable_to_non_nullable
          : content as String,
    );
  }
}

extension $BotTemplateFileMemoriesInnerCopyWith
    on BotTemplateFileMemoriesInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotTemplateFileMemoriesInner.copyWith(...)` or `instanceOfBotTemplateFileMemoriesInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotTemplateFileMemoriesInnerCWProxy get copyWith =>
      _$BotTemplateFileMemoriesInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotTemplateFileMemoriesInner _$BotTemplateFileMemoriesInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('BotTemplateFileMemoriesInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['kind', 'content']);
  final val = BotTemplateFileMemoriesInner(
    kind: $checkedConvert(
      'kind',
      (v) => $enumDecode(_$BotTemplateFileMemoriesInnerKindEnumEnumMap, v),
    ),
    content: $checkedConvert('content', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$BotTemplateFileMemoriesInnerToJson(
  BotTemplateFileMemoriesInner instance,
) => <String, dynamic>{
  'kind': _$BotTemplateFileMemoriesInnerKindEnumEnumMap[instance.kind]!,
  'content': instance.content,
};

const _$BotTemplateFileMemoriesInnerKindEnumEnumMap = {
  BotTemplateFileMemoriesInnerKindEnum.fact: 'fact',
  BotTemplateFileMemoriesInnerKindEnum.episode: 'episode',
  BotTemplateFileMemoriesInnerKindEnum.summary: 'summary',
  BotTemplateFileMemoriesInnerKindEnum.preference: 'preference',
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_web_chat_request_messages_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SupportWebChatRequestMessagesInnerCWProxy {
  SupportWebChatRequestMessagesInner role(
    SupportWebChatRequestMessagesInnerRoleEnum role,
  );

  SupportWebChatRequestMessagesInner content(String content);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportWebChatRequestMessagesInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportWebChatRequestMessagesInner(...).copyWith(id: 12, name: "My name")
  /// ```
  SupportWebChatRequestMessagesInner call({
    SupportWebChatRequestMessagesInnerRoleEnum role,
    String content,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSupportWebChatRequestMessagesInner.copyWith(...)` or call `instanceOfSupportWebChatRequestMessagesInner.copyWith.fieldName(value)` for a single field.
class _$SupportWebChatRequestMessagesInnerCWProxyImpl
    implements _$SupportWebChatRequestMessagesInnerCWProxy {
  const _$SupportWebChatRequestMessagesInnerCWProxyImpl(this._value);

  final SupportWebChatRequestMessagesInner _value;

  @override
  SupportWebChatRequestMessagesInner role(
    SupportWebChatRequestMessagesInnerRoleEnum role,
  ) => call(role: role);

  @override
  SupportWebChatRequestMessagesInner content(String content) =>
      call(content: content);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportWebChatRequestMessagesInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportWebChatRequestMessagesInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SupportWebChatRequestMessagesInner call({
    Object? role = const $CopyWithPlaceholder(),
    Object? content = const $CopyWithPlaceholder(),
  }) {
    return SupportWebChatRequestMessagesInner(
      role: role == const $CopyWithPlaceholder() || role == null
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as SupportWebChatRequestMessagesInnerRoleEnum,
      content: content == const $CopyWithPlaceholder() || content == null
          ? _value.content
          // ignore: cast_nullable_to_non_nullable
          : content as String,
    );
  }
}

extension $SupportWebChatRequestMessagesInnerCopyWith
    on SupportWebChatRequestMessagesInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSupportWebChatRequestMessagesInner.copyWith(...)` or `instanceOfSupportWebChatRequestMessagesInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SupportWebChatRequestMessagesInnerCWProxy get copyWith =>
      _$SupportWebChatRequestMessagesInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportWebChatRequestMessagesInner _$SupportWebChatRequestMessagesInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SupportWebChatRequestMessagesInner', json, (
  $checkedConvert,
) {
  $checkKeys(json, requiredKeys: const ['role', 'content']);
  final val = SupportWebChatRequestMessagesInner(
    role: $checkedConvert(
      'role',
      (v) =>
          $enumDecode(_$SupportWebChatRequestMessagesInnerRoleEnumEnumMap, v),
    ),
    content: $checkedConvert('content', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$SupportWebChatRequestMessagesInnerToJson(
  SupportWebChatRequestMessagesInner instance,
) => <String, dynamic>{
  'role': _$SupportWebChatRequestMessagesInnerRoleEnumEnumMap[instance.role]!,
  'content': instance.content,
};

const _$SupportWebChatRequestMessagesInnerRoleEnumEnumMap = {
  SupportWebChatRequestMessagesInnerRoleEnum.user: 'user',
  SupportWebChatRequestMessagesInnerRoleEnum.assistant: 'assistant',
};

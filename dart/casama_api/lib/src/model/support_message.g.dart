// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_message.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SupportMessageCWProxy {
  SupportMessage role(SupportMessageRoleEnum role);

  SupportMessage content(String content);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportMessage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportMessage(...).copyWith(id: 12, name: "My name")
  /// ```
  SupportMessage call({SupportMessageRoleEnum role, String content});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSupportMessage.copyWith(...)` or call `instanceOfSupportMessage.copyWith.fieldName(value)` for a single field.
class _$SupportMessageCWProxyImpl implements _$SupportMessageCWProxy {
  const _$SupportMessageCWProxyImpl(this._value);

  final SupportMessage _value;

  @override
  SupportMessage role(SupportMessageRoleEnum role) => call(role: role);

  @override
  SupportMessage content(String content) => call(content: content);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportMessage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportMessage(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SupportMessage call({
    Object? role = const $CopyWithPlaceholder(),
    Object? content = const $CopyWithPlaceholder(),
  }) {
    return SupportMessage(
      role: role == const $CopyWithPlaceholder() || role == null
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as SupportMessageRoleEnum,
      content: content == const $CopyWithPlaceholder() || content == null
          ? _value.content
          // ignore: cast_nullable_to_non_nullable
          : content as String,
    );
  }
}

extension $SupportMessageCopyWith on SupportMessage {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSupportMessage.copyWith(...)` or `instanceOfSupportMessage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SupportMessageCWProxy get copyWith => _$SupportMessageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportMessage _$SupportMessageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SupportMessage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['role', 'content']);
      final val = SupportMessage(
        role: $checkedConvert(
          'role',
          (v) => $enumDecode(_$SupportMessageRoleEnumEnumMap, v),
        ),
        content: $checkedConvert('content', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SupportMessageToJson(SupportMessage instance) =>
    <String, dynamic>{
      'role': _$SupportMessageRoleEnumEnumMap[instance.role]!,
      'content': instance.content,
    };

const _$SupportMessageRoleEnumEnumMap = {
  SupportMessageRoleEnum.user: 'user',
  SupportMessageRoleEnum.assistant: 'assistant',
};

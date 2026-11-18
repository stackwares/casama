// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'answer_mcp_question_body.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AnswerMcpQuestionBodyCWProxy {
  AnswerMcpQuestionBody action(AnswerMcpQuestionBodyActionEnum action);

  AnswerMcpQuestionBody content(Map<String, Object?>? content);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AnswerMcpQuestionBody(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AnswerMcpQuestionBody(...).copyWith(id: 12, name: "My name")
  /// ```
  AnswerMcpQuestionBody call({
    AnswerMcpQuestionBodyActionEnum action,
    Map<String, Object?>? content,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAnswerMcpQuestionBody.copyWith(...)` or call `instanceOfAnswerMcpQuestionBody.copyWith.fieldName(value)` for a single field.
class _$AnswerMcpQuestionBodyCWProxyImpl
    implements _$AnswerMcpQuestionBodyCWProxy {
  const _$AnswerMcpQuestionBodyCWProxyImpl(this._value);

  final AnswerMcpQuestionBody _value;

  @override
  AnswerMcpQuestionBody action(AnswerMcpQuestionBodyActionEnum action) =>
      call(action: action);

  @override
  AnswerMcpQuestionBody content(Map<String, Object?>? content) =>
      call(content: content);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AnswerMcpQuestionBody(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AnswerMcpQuestionBody(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AnswerMcpQuestionBody call({
    Object? action = const $CopyWithPlaceholder(),
    Object? content = const $CopyWithPlaceholder(),
  }) {
    return AnswerMcpQuestionBody(
      action: action == const $CopyWithPlaceholder() || action == null
          ? _value.action
          // ignore: cast_nullable_to_non_nullable
          : action as AnswerMcpQuestionBodyActionEnum,
      content: content == const $CopyWithPlaceholder()
          ? _value.content
          // ignore: cast_nullable_to_non_nullable
          : content as Map<String, Object?>?,
    );
  }
}

extension $AnswerMcpQuestionBodyCopyWith on AnswerMcpQuestionBody {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAnswerMcpQuestionBody.copyWith(...)` or `instanceOfAnswerMcpQuestionBody.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AnswerMcpQuestionBodyCWProxy get copyWith =>
      _$AnswerMcpQuestionBodyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnswerMcpQuestionBody _$AnswerMcpQuestionBodyFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AnswerMcpQuestionBody', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['action']);
  final val = AnswerMcpQuestionBody(
    action: $checkedConvert(
      'action',
      (v) => $enumDecode(_$AnswerMcpQuestionBodyActionEnumEnumMap, v),
    ),
    content: $checkedConvert('content', (v) => v as Map<String, dynamic>?),
  );
  return val;
});

Map<String, dynamic> _$AnswerMcpQuestionBodyToJson(
  AnswerMcpQuestionBody instance,
) => <String, dynamic>{
  'action': _$AnswerMcpQuestionBodyActionEnumEnumMap[instance.action]!,
  'content': ?instance.content,
};

const _$AnswerMcpQuestionBodyActionEnumEnumMap = {
  AnswerMcpQuestionBodyActionEnum.accept: 'accept',
  AnswerMcpQuestionBodyActionEnum.decline: 'decline',
  AnswerMcpQuestionBodyActionEnum.cancel: 'cancel',
};

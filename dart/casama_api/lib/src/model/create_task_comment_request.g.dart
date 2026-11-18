// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_task_comment_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateTaskCommentRequestCWProxy {
  CreateTaskCommentRequest bodyMd(String bodyMd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateTaskCommentRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateTaskCommentRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateTaskCommentRequest call({String bodyMd});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateTaskCommentRequest.copyWith(...)` or call `instanceOfCreateTaskCommentRequest.copyWith.fieldName(value)` for a single field.
class _$CreateTaskCommentRequestCWProxyImpl
    implements _$CreateTaskCommentRequestCWProxy {
  const _$CreateTaskCommentRequestCWProxyImpl(this._value);

  final CreateTaskCommentRequest _value;

  @override
  CreateTaskCommentRequest bodyMd(String bodyMd) => call(bodyMd: bodyMd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateTaskCommentRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateTaskCommentRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateTaskCommentRequest call({
    Object? bodyMd = const $CopyWithPlaceholder(),
  }) {
    return CreateTaskCommentRequest(
      bodyMd: bodyMd == const $CopyWithPlaceholder() || bodyMd == null
          ? _value.bodyMd
          // ignore: cast_nullable_to_non_nullable
          : bodyMd as String,
    );
  }
}

extension $CreateTaskCommentRequestCopyWith on CreateTaskCommentRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateTaskCommentRequest.copyWith(...)` or `instanceOfCreateTaskCommentRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateTaskCommentRequestCWProxy get copyWith =>
      _$CreateTaskCommentRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateTaskCommentRequest _$CreateTaskCommentRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateTaskCommentRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['body_md']);
  final val = CreateTaskCommentRequest(
    bodyMd: $checkedConvert('body_md', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'bodyMd': 'body_md'});

Map<String, dynamic> _$CreateTaskCommentRequestToJson(
  CreateTaskCommentRequest instance,
) => <String, dynamic>{'body_md': instance.bodyMd};

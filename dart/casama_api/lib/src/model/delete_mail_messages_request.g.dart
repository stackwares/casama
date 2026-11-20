// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_mail_messages_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeleteMailMessagesRequestCWProxy {
  DeleteMailMessagesRequest ids(List<String>? ids);

  DeleteMailMessagesRequest before(DateTime? before);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeleteMailMessagesRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeleteMailMessagesRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  DeleteMailMessagesRequest call({List<String>? ids, DateTime? before});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeleteMailMessagesRequest.copyWith(...)` or call `instanceOfDeleteMailMessagesRequest.copyWith.fieldName(value)` for a single field.
class _$DeleteMailMessagesRequestCWProxyImpl
    implements _$DeleteMailMessagesRequestCWProxy {
  const _$DeleteMailMessagesRequestCWProxyImpl(this._value);

  final DeleteMailMessagesRequest _value;

  @override
  DeleteMailMessagesRequest ids(List<String>? ids) => call(ids: ids);

  @override
  DeleteMailMessagesRequest before(DateTime? before) => call(before: before);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeleteMailMessagesRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeleteMailMessagesRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeleteMailMessagesRequest call({
    Object? ids = const $CopyWithPlaceholder(),
    Object? before = const $CopyWithPlaceholder(),
  }) {
    return DeleteMailMessagesRequest(
      ids: ids == const $CopyWithPlaceholder()
          ? _value.ids
          // ignore: cast_nullable_to_non_nullable
          : ids as List<String>?,
      before: before == const $CopyWithPlaceholder()
          ? _value.before
          // ignore: cast_nullable_to_non_nullable
          : before as DateTime?,
    );
  }
}

extension $DeleteMailMessagesRequestCopyWith on DeleteMailMessagesRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeleteMailMessagesRequest.copyWith(...)` or `instanceOfDeleteMailMessagesRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeleteMailMessagesRequestCWProxy get copyWith =>
      _$DeleteMailMessagesRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteMailMessagesRequest _$DeleteMailMessagesRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DeleteMailMessagesRequest', json, ($checkedConvert) {
  final val = DeleteMailMessagesRequest(
    ids: $checkedConvert(
      'ids',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
    ),
    before: $checkedConvert(
      'before',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
  );
  return val;
});

Map<String, dynamic> _$DeleteMailMessagesRequestToJson(
  DeleteMailMessagesRequest instance,
) => <String, dynamic>{
  'ids': ?instance.ids,
  'before': ?instance.before?.toIso8601String(),
};

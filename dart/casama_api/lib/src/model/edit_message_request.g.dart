// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_message_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EditMessageRequestCWProxy {
  EditMessageRequest text(String text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EditMessageRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EditMessageRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  EditMessageRequest call({String text});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfEditMessageRequest.copyWith(...)` or call `instanceOfEditMessageRequest.copyWith.fieldName(value)` for a single field.
class _$EditMessageRequestCWProxyImpl implements _$EditMessageRequestCWProxy {
  const _$EditMessageRequestCWProxyImpl(this._value);

  final EditMessageRequest _value;

  @override
  EditMessageRequest text(String text) => call(text: text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EditMessageRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EditMessageRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  EditMessageRequest call({Object? text = const $CopyWithPlaceholder()}) {
    return EditMessageRequest(
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $EditMessageRequestCopyWith on EditMessageRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfEditMessageRequest.copyWith(...)` or `instanceOfEditMessageRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EditMessageRequestCWProxy get copyWith =>
      _$EditMessageRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EditMessageRequest _$EditMessageRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EditMessageRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['text']);
      final val = EditMessageRequest(
        text: $checkedConvert('text', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$EditMessageRequestToJson(EditMessageRequest instance) =>
    <String, dynamic>{'text': instance.text};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_starter.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TextStarterCWProxy {
  TextStarter id(String id);

  TextStarter text(String text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TextStarter(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TextStarter(...).copyWith(id: 12, name: "My name")
  /// ```
  TextStarter call({String id, String text});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTextStarter.copyWith(...)` or call `instanceOfTextStarter.copyWith.fieldName(value)` for a single field.
class _$TextStarterCWProxyImpl implements _$TextStarterCWProxy {
  const _$TextStarterCWProxyImpl(this._value);

  final TextStarter _value;

  @override
  TextStarter id(String id) => call(id: id);

  @override
  TextStarter text(String text) => call(text: text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TextStarter(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TextStarter(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TextStarter call({
    Object? id = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return TextStarter(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $TextStarterCopyWith on TextStarter {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTextStarter.copyWith(...)` or `instanceOfTextStarter.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TextStarterCWProxy get copyWith => _$TextStarterCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextStarter _$TextStarterFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TextStarter', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'text']);
      final val = TextStarter(
        id: $checkedConvert('id', (v) => v as String),
        text: $checkedConvert('text', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$TextStarterToJson(TextStarter instance) =>
    <String, dynamic>{'id': instance.id, 'text': instance.text};

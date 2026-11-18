// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_reaction_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetReactionRequestCWProxy {
  SetReactionRequest emoji(String emoji);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetReactionRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetReactionRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetReactionRequest call({String emoji});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetReactionRequest.copyWith(...)` or call `instanceOfSetReactionRequest.copyWith.fieldName(value)` for a single field.
class _$SetReactionRequestCWProxyImpl implements _$SetReactionRequestCWProxy {
  const _$SetReactionRequestCWProxyImpl(this._value);

  final SetReactionRequest _value;

  @override
  SetReactionRequest emoji(String emoji) => call(emoji: emoji);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetReactionRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetReactionRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetReactionRequest call({Object? emoji = const $CopyWithPlaceholder()}) {
    return SetReactionRequest(
      emoji: emoji == const $CopyWithPlaceholder() || emoji == null
          ? _value.emoji
          // ignore: cast_nullable_to_non_nullable
          : emoji as String,
    );
  }
}

extension $SetReactionRequestCopyWith on SetReactionRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetReactionRequest.copyWith(...)` or `instanceOfSetReactionRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetReactionRequestCWProxy get copyWith =>
      _$SetReactionRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetReactionRequest _$SetReactionRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SetReactionRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['emoji']);
      final val = SetReactionRequest(
        emoji: $checkedConvert('emoji', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SetReactionRequestToJson(SetReactionRequest instance) =>
    <String, dynamic>{'emoji': instance.emoji};

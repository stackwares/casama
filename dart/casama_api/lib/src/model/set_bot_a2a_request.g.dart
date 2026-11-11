// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_bot_a2a_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetBotA2aRequestCWProxy {
  SetBotA2aRequest published(bool published);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetBotA2aRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetBotA2aRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetBotA2aRequest call({bool published});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetBotA2aRequest.copyWith(...)` or call `instanceOfSetBotA2aRequest.copyWith.fieldName(value)` for a single field.
class _$SetBotA2aRequestCWProxyImpl implements _$SetBotA2aRequestCWProxy {
  const _$SetBotA2aRequestCWProxyImpl(this._value);

  final SetBotA2aRequest _value;

  @override
  SetBotA2aRequest published(bool published) => call(published: published);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetBotA2aRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetBotA2aRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetBotA2aRequest call({Object? published = const $CopyWithPlaceholder()}) {
    return SetBotA2aRequest(
      published: published == const $CopyWithPlaceholder() || published == null
          ? _value.published
          // ignore: cast_nullable_to_non_nullable
          : published as bool,
    );
  }
}

extension $SetBotA2aRequestCopyWith on SetBotA2aRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetBotA2aRequest.copyWith(...)` or `instanceOfSetBotA2aRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetBotA2aRequestCWProxy get copyWith => _$SetBotA2aRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetBotA2aRequest _$SetBotA2aRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SetBotA2aRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['published']);
      final val = SetBotA2aRequest(
        published: $checkedConvert('published', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$SetBotA2aRequestToJson(SetBotA2aRequest instance) =>
    <String, dynamic>{'published': instance.published};

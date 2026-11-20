// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generate_bot_pictures_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GenerateBotPicturesRequestCWProxy {
  GenerateBotPicturesRequest style(BotPictureStyle style);

  GenerateBotPicturesRequest description(String? description);

  GenerateBotPicturesRequest count(int? count);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GenerateBotPicturesRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GenerateBotPicturesRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  GenerateBotPicturesRequest call({
    BotPictureStyle style,
    String? description,
    int? count,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGenerateBotPicturesRequest.copyWith(...)` or call `instanceOfGenerateBotPicturesRequest.copyWith.fieldName(value)` for a single field.
class _$GenerateBotPicturesRequestCWProxyImpl
    implements _$GenerateBotPicturesRequestCWProxy {
  const _$GenerateBotPicturesRequestCWProxyImpl(this._value);

  final GenerateBotPicturesRequest _value;

  @override
  GenerateBotPicturesRequest style(BotPictureStyle style) => call(style: style);

  @override
  GenerateBotPicturesRequest description(String? description) =>
      call(description: description);

  @override
  GenerateBotPicturesRequest count(int? count) => call(count: count);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GenerateBotPicturesRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GenerateBotPicturesRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GenerateBotPicturesRequest call({
    Object? style = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
  }) {
    return GenerateBotPicturesRequest(
      style: style == const $CopyWithPlaceholder() || style == null
          ? _value.style
          // ignore: cast_nullable_to_non_nullable
          : style as BotPictureStyle,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String?,
      count: count == const $CopyWithPlaceholder()
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int?,
    );
  }
}

extension $GenerateBotPicturesRequestCopyWith on GenerateBotPicturesRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGenerateBotPicturesRequest.copyWith(...)` or `instanceOfGenerateBotPicturesRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GenerateBotPicturesRequestCWProxy get copyWith =>
      _$GenerateBotPicturesRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenerateBotPicturesRequest _$GenerateBotPicturesRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GenerateBotPicturesRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['style']);
  final val = GenerateBotPicturesRequest(
    style: $checkedConvert(
      'style',
      (v) => $enumDecode(_$BotPictureStyleEnumMap, v),
    ),
    description: $checkedConvert('description', (v) => v as String?),
    count: $checkedConvert('count', (v) => (v as num?)?.toInt()),
  );
  return val;
});

Map<String, dynamic> _$GenerateBotPicturesRequestToJson(
  GenerateBotPicturesRequest instance,
) => <String, dynamic>{
  'style': _$BotPictureStyleEnumMap[instance.style]!,
  'description': ?instance.description,
  'count': ?instance.count,
};

const _$BotPictureStyleEnumMap = {
  BotPictureStyle.cloud: 'cloud',
  BotPictureStyle.soft3d: 'soft3d',
  BotPictureStyle.watercolor: 'watercolor',
  BotPictureStyle.flat: 'flat',
  BotPictureStyle.pixel: 'pixel',
  BotPictureStyle.line: 'line',
  BotPictureStyle.photo: 'photo',
};

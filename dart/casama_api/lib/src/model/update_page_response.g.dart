// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_page_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdatePageResponseCWProxy {
  UpdatePageResponse page(BotPage page);

  UpdatePageResponse publicUrl(String? publicUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdatePageResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdatePageResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdatePageResponse call({BotPage page, String? publicUrl});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdatePageResponse.copyWith(...)` or call `instanceOfUpdatePageResponse.copyWith.fieldName(value)` for a single field.
class _$UpdatePageResponseCWProxyImpl implements _$UpdatePageResponseCWProxy {
  const _$UpdatePageResponseCWProxyImpl(this._value);

  final UpdatePageResponse _value;

  @override
  UpdatePageResponse page(BotPage page) => call(page: page);

  @override
  UpdatePageResponse publicUrl(String? publicUrl) => call(publicUrl: publicUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdatePageResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdatePageResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdatePageResponse call({
    Object? page = const $CopyWithPlaceholder(),
    Object? publicUrl = const $CopyWithPlaceholder(),
  }) {
    return UpdatePageResponse(
      page: page == const $CopyWithPlaceholder() || page == null
          ? _value.page
          // ignore: cast_nullable_to_non_nullable
          : page as BotPage,
      publicUrl: publicUrl == const $CopyWithPlaceholder()
          ? _value.publicUrl
          // ignore: cast_nullable_to_non_nullable
          : publicUrl as String?,
    );
  }
}

extension $UpdatePageResponseCopyWith on UpdatePageResponse {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdatePageResponse.copyWith(...)` or `instanceOfUpdatePageResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdatePageResponseCWProxy get copyWith =>
      _$UpdatePageResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdatePageResponse _$UpdatePageResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdatePageResponse', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['page', 'public_url']);
      final val = UpdatePageResponse(
        page: $checkedConvert(
          'page',
          (v) => BotPage.fromJson(v as Map<String, dynamic>),
        ),
        publicUrl: $checkedConvert('public_url', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'publicUrl': 'public_url'});

Map<String, dynamic> _$UpdatePageResponseToJson(UpdatePageResponse instance) =>
    <String, dynamic>{
      'page': instance.page.toJson(),
      'public_url': instance.publicUrl,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_view_link_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PageViewLinkRequestCWProxy {
  PageViewLinkRequest format(PageViewLinkRequestFormatEnum? format);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PageViewLinkRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PageViewLinkRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  PageViewLinkRequest call({PageViewLinkRequestFormatEnum? format});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPageViewLinkRequest.copyWith(...)` or call `instanceOfPageViewLinkRequest.copyWith.fieldName(value)` for a single field.
class _$PageViewLinkRequestCWProxyImpl implements _$PageViewLinkRequestCWProxy {
  const _$PageViewLinkRequestCWProxyImpl(this._value);

  final PageViewLinkRequest _value;

  @override
  PageViewLinkRequest format(PageViewLinkRequestFormatEnum? format) =>
      call(format: format);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PageViewLinkRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PageViewLinkRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PageViewLinkRequest call({Object? format = const $CopyWithPlaceholder()}) {
    return PageViewLinkRequest(
      format: format == const $CopyWithPlaceholder()
          ? _value.format
          // ignore: cast_nullable_to_non_nullable
          : format as PageViewLinkRequestFormatEnum?,
    );
  }
}

extension $PageViewLinkRequestCopyWith on PageViewLinkRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPageViewLinkRequest.copyWith(...)` or `instanceOfPageViewLinkRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PageViewLinkRequestCWProxy get copyWith =>
      _$PageViewLinkRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageViewLinkRequest _$PageViewLinkRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PageViewLinkRequest', json, ($checkedConvert) {
      final val = PageViewLinkRequest(
        format: $checkedConvert(
          'format',
          (v) => $enumDecodeNullable(_$PageViewLinkRequestFormatEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PageViewLinkRequestToJson(
  PageViewLinkRequest instance,
) => <String, dynamic>{
  'format': ?_$PageViewLinkRequestFormatEnumEnumMap[instance.format],
};

const _$PageViewLinkRequestFormatEnumEnumMap = {
  PageViewLinkRequestFormatEnum.html: 'html',
  PageViewLinkRequestFormatEnum.pdf: 'pdf',
};

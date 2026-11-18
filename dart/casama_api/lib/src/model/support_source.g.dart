// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_source.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SupportSourceCWProxy {
  SupportSource title(String title);

  SupportSource url(String url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportSource(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportSource(...).copyWith(id: 12, name: "My name")
  /// ```
  SupportSource call({String title, String url});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSupportSource.copyWith(...)` or call `instanceOfSupportSource.copyWith.fieldName(value)` for a single field.
class _$SupportSourceCWProxyImpl implements _$SupportSourceCWProxy {
  const _$SupportSourceCWProxyImpl(this._value);

  final SupportSource _value;

  @override
  SupportSource title(String title) => call(title: title);

  @override
  SupportSource url(String url) => call(url: url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportSource(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportSource(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SupportSource call({
    Object? title = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
  }) {
    return SupportSource(
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
    );
  }
}

extension $SupportSourceCopyWith on SupportSource {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSupportSource.copyWith(...)` or `instanceOfSupportSource.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SupportSourceCWProxy get copyWith => _$SupportSourceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportSource _$SupportSourceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SupportSource', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['title', 'url']);
      final val = SupportSource(
        title: $checkedConvert('title', (v) => v as String),
        url: $checkedConvert('url', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SupportSourceToJson(SupportSource instance) =>
    <String, dynamic>{'title': instance.title, 'url': instance.url};

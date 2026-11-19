// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_place.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SupportPlaceCWProxy {
  SupportPlace id(String id);

  SupportPlace label(String label);

  SupportPlace route(String? route);

  SupportPlace url(String url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportPlace(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportPlace(...).copyWith(id: 12, name: "My name")
  /// ```
  SupportPlace call({String id, String label, String? route, String url});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSupportPlace.copyWith(...)` or call `instanceOfSupportPlace.copyWith.fieldName(value)` for a single field.
class _$SupportPlaceCWProxyImpl implements _$SupportPlaceCWProxy {
  const _$SupportPlaceCWProxyImpl(this._value);

  final SupportPlace _value;

  @override
  SupportPlace id(String id) => call(id: id);

  @override
  SupportPlace label(String label) => call(label: label);

  @override
  SupportPlace route(String? route) => call(route: route);

  @override
  SupportPlace url(String url) => call(url: url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportPlace(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportPlace(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SupportPlace call({
    Object? id = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? route = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
  }) {
    return SupportPlace(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      route: route == const $CopyWithPlaceholder()
          ? _value.route
          // ignore: cast_nullable_to_non_nullable
          : route as String?,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
    );
  }
}

extension $SupportPlaceCopyWith on SupportPlace {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSupportPlace.copyWith(...)` or `instanceOfSupportPlace.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SupportPlaceCWProxy get copyWith => _$SupportPlaceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportPlace _$SupportPlaceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SupportPlace', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'label', 'url']);
      final val = SupportPlace(
        id: $checkedConvert('id', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String),
        route: $checkedConvert('route', (v) => v as String?),
        url: $checkedConvert('url', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SupportPlaceToJson(SupportPlace instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'route': ?instance.route,
      'url': instance.url,
    };

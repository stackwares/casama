// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_version.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PageVersionCWProxy {
  PageVersion version(int version);

  PageVersion createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PageVersion(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PageVersion(...).copyWith(id: 12, name: "My name")
  /// ```
  PageVersion call({int version, DateTime createdAt});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPageVersion.copyWith(...)` or call `instanceOfPageVersion.copyWith.fieldName(value)` for a single field.
class _$PageVersionCWProxyImpl implements _$PageVersionCWProxy {
  const _$PageVersionCWProxyImpl(this._value);

  final PageVersion _value;

  @override
  PageVersion version(int version) => call(version: version);

  @override
  PageVersion createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PageVersion(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PageVersion(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PageVersion call({
    Object? version = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return PageVersion(
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $PageVersionCopyWith on PageVersion {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPageVersion.copyWith(...)` or `instanceOfPageVersion.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PageVersionCWProxy get copyWith => _$PageVersionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageVersion _$PageVersionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PageVersion', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['version', 'created_at']);
      final val = PageVersion(
        version: $checkedConvert('version', (v) => (v as num).toInt()),
        createdAt: $checkedConvert(
          'created_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'createdAt': 'created_at'});

Map<String, dynamic> _$PageVersionToJson(PageVersion instance) =>
    <String, dynamic>{
      'version': instance.version,
      'created_at': instance.createdAt.toIso8601String(),
    };

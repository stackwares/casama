// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_share_view.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackShareViewCWProxy {
  PackShareView id(String id);

  PackShareView preview(PackPreview preview);

  PackShareView expiresAt(DateTime expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackShareView(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackShareView(...).copyWith(id: 12, name: "My name")
  /// ```
  PackShareView call({String id, PackPreview preview, DateTime expiresAt});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackShareView.copyWith(...)` or call `instanceOfPackShareView.copyWith.fieldName(value)` for a single field.
class _$PackShareViewCWProxyImpl implements _$PackShareViewCWProxy {
  const _$PackShareViewCWProxyImpl(this._value);

  final PackShareView _value;

  @override
  PackShareView id(String id) => call(id: id);

  @override
  PackShareView preview(PackPreview preview) => call(preview: preview);

  @override
  PackShareView expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackShareView(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackShareView(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackShareView call({
    Object? id = const $CopyWithPlaceholder(),
    Object? preview = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
  }) {
    return PackShareView(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      preview: preview == const $CopyWithPlaceholder() || preview == null
          ? _value.preview
          // ignore: cast_nullable_to_non_nullable
          : preview as PackPreview,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
    );
  }
}

extension $PackShareViewCopyWith on PackShareView {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackShareView.copyWith(...)` or `instanceOfPackShareView.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackShareViewCWProxy get copyWith => _$PackShareViewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackShareView _$PackShareViewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PackShareView', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'preview', 'expires_at']);
      final val = PackShareView(
        id: $checkedConvert('id', (v) => v as String),
        preview: $checkedConvert(
          'preview',
          (v) => PackPreview.fromJson(v as Map<String, dynamic>),
        ),
        expiresAt: $checkedConvert(
          'expires_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'expiresAt': 'expires_at'});

Map<String, dynamic> _$PackShareViewToJson(PackShareView instance) =>
    <String, dynamic>{
      'id': instance.id,
      'preview': instance.preview.toJson(),
      'expires_at': instance.expiresAt.toIso8601String(),
    };

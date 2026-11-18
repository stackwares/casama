// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'widget_key_created.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WidgetKeyCreatedCWProxy {
  WidgetKeyCreated id(String id);

  WidgetKeyCreated key(String key);

  WidgetKeyCreated createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WidgetKeyCreated(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WidgetKeyCreated(...).copyWith(id: 12, name: "My name")
  /// ```
  WidgetKeyCreated call({String id, String key, DateTime createdAt});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWidgetKeyCreated.copyWith(...)` or call `instanceOfWidgetKeyCreated.copyWith.fieldName(value)` for a single field.
class _$WidgetKeyCreatedCWProxyImpl implements _$WidgetKeyCreatedCWProxy {
  const _$WidgetKeyCreatedCWProxyImpl(this._value);

  final WidgetKeyCreated _value;

  @override
  WidgetKeyCreated id(String id) => call(id: id);

  @override
  WidgetKeyCreated key(String key) => call(key: key);

  @override
  WidgetKeyCreated createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WidgetKeyCreated(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WidgetKeyCreated(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WidgetKeyCreated call({
    Object? id = const $CopyWithPlaceholder(),
    Object? key = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return WidgetKeyCreated(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      key: key == const $CopyWithPlaceholder() || key == null
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $WidgetKeyCreatedCopyWith on WidgetKeyCreated {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWidgetKeyCreated.copyWith(...)` or `instanceOfWidgetKeyCreated.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WidgetKeyCreatedCWProxy get copyWith => _$WidgetKeyCreatedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WidgetKeyCreated _$WidgetKeyCreatedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WidgetKeyCreated', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'key', 'created_at']);
      final val = WidgetKeyCreated(
        id: $checkedConvert('id', (v) => v as String),
        key: $checkedConvert('key', (v) => v as String),
        createdAt: $checkedConvert(
          'created_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'createdAt': 'created_at'});

Map<String, dynamic> _$WidgetKeyCreatedToJson(WidgetKeyCreated instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'created_at': instance.createdAt.toIso8601String(),
    };

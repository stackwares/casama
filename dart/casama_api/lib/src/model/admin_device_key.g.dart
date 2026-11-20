// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_device_key.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminDeviceKeyCWProxy {
  AdminDeviceKey id(String id);

  AdminDeviceKey name(String name);

  AdminDeviceKey createdAt(DateTime createdAt);

  AdminDeviceKey lastUsedAt(DateTime? lastUsedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminDeviceKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminDeviceKey(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminDeviceKey call({
    String id,
    String name,
    DateTime createdAt,
    DateTime? lastUsedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminDeviceKey.copyWith(...)` or call `instanceOfAdminDeviceKey.copyWith.fieldName(value)` for a single field.
class _$AdminDeviceKeyCWProxyImpl implements _$AdminDeviceKeyCWProxy {
  const _$AdminDeviceKeyCWProxyImpl(this._value);

  final AdminDeviceKey _value;

  @override
  AdminDeviceKey id(String id) => call(id: id);

  @override
  AdminDeviceKey name(String name) => call(name: name);

  @override
  AdminDeviceKey createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  AdminDeviceKey lastUsedAt(DateTime? lastUsedAt) =>
      call(lastUsedAt: lastUsedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminDeviceKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminDeviceKey(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminDeviceKey call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? lastUsedAt = const $CopyWithPlaceholder(),
  }) {
    return AdminDeviceKey(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      lastUsedAt: lastUsedAt == const $CopyWithPlaceholder()
          ? _value.lastUsedAt
          // ignore: cast_nullable_to_non_nullable
          : lastUsedAt as DateTime?,
    );
  }
}

extension $AdminDeviceKeyCopyWith on AdminDeviceKey {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminDeviceKey.copyWith(...)` or `instanceOfAdminDeviceKey.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminDeviceKeyCWProxy get copyWith => _$AdminDeviceKeyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminDeviceKey _$AdminDeviceKeyFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminDeviceKey',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'name', 'created_at', 'last_used_at'],
        );
        final val = AdminDeviceKey(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          lastUsedAt: $checkedConvert(
            'last_used_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'createdAt': 'created_at',
        'lastUsedAt': 'last_used_at',
      },
    );

Map<String, dynamic> _$AdminDeviceKeyToJson(AdminDeviceKey instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'created_at': instance.createdAt.toIso8601String(),
      'last_used_at': instance.lastUsedAt?.toIso8601String(),
    };

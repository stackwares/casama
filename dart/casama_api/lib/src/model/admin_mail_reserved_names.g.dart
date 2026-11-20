// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_mail_reserved_names.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminMailReservedNamesCWProxy {
  AdminMailReservedNames names(List<String> names);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMailReservedNames(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMailReservedNames(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminMailReservedNames call({List<String> names});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminMailReservedNames.copyWith(...)` or call `instanceOfAdminMailReservedNames.copyWith.fieldName(value)` for a single field.
class _$AdminMailReservedNamesCWProxyImpl
    implements _$AdminMailReservedNamesCWProxy {
  const _$AdminMailReservedNamesCWProxyImpl(this._value);

  final AdminMailReservedNames _value;

  @override
  AdminMailReservedNames names(List<String> names) => call(names: names);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMailReservedNames(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMailReservedNames(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminMailReservedNames call({Object? names = const $CopyWithPlaceholder()}) {
    return AdminMailReservedNames(
      names: names == const $CopyWithPlaceholder() || names == null
          ? _value.names
          // ignore: cast_nullable_to_non_nullable
          : names as List<String>,
    );
  }
}

extension $AdminMailReservedNamesCopyWith on AdminMailReservedNames {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminMailReservedNames.copyWith(...)` or `instanceOfAdminMailReservedNames.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminMailReservedNamesCWProxy get copyWith =>
      _$AdminMailReservedNamesCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminMailReservedNames _$AdminMailReservedNamesFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminMailReservedNames', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['names']);
  final val = AdminMailReservedNames(
    names: $checkedConvert(
      'names',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$AdminMailReservedNamesToJson(
  AdminMailReservedNames instance,
) => <String, dynamic>{'names': instance.names};

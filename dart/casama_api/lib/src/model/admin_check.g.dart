// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_check.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminCheckCWProxy {
  AdminCheck verifiedAt(DateTime verifiedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminCheck(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminCheck(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminCheck call({DateTime verifiedAt});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminCheck.copyWith(...)` or call `instanceOfAdminCheck.copyWith.fieldName(value)` for a single field.
class _$AdminCheckCWProxyImpl implements _$AdminCheckCWProxy {
  const _$AdminCheckCWProxyImpl(this._value);

  final AdminCheck _value;

  @override
  AdminCheck verifiedAt(DateTime verifiedAt) => call(verifiedAt: verifiedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminCheck(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminCheck(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminCheck call({Object? verifiedAt = const $CopyWithPlaceholder()}) {
    return AdminCheck(
      verifiedAt:
          verifiedAt == const $CopyWithPlaceholder() || verifiedAt == null
          ? _value.verifiedAt
          // ignore: cast_nullable_to_non_nullable
          : verifiedAt as DateTime,
    );
  }
}

extension $AdminCheckCopyWith on AdminCheck {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminCheck.copyWith(...)` or `instanceOfAdminCheck.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminCheckCWProxy get copyWith => _$AdminCheckCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminCheck _$AdminCheckFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminCheck', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['verified_at']);
      final val = AdminCheck(
        verifiedAt: $checkedConvert(
          'verified_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'verifiedAt': 'verified_at'});

Map<String, dynamic> _$AdminCheckToJson(AdminCheck instance) =>
    <String, dynamic>{'verified_at': instance.verifiedAt.toIso8601String()};

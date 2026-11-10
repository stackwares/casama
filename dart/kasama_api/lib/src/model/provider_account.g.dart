// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_account.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProviderAccountCWProxy {
  ProviderAccount app(String app);

  ProviderAccount status(ProviderAccountStatusEnum status);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderAccount(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderAccount(...).copyWith(id: 12, name: "My name")
  /// ```
  ProviderAccount call({String app, ProviderAccountStatusEnum status});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProviderAccount.copyWith(...)` or call `instanceOfProviderAccount.copyWith.fieldName(value)` for a single field.
class _$ProviderAccountCWProxyImpl implements _$ProviderAccountCWProxy {
  const _$ProviderAccountCWProxyImpl(this._value);

  final ProviderAccount _value;

  @override
  ProviderAccount app(String app) => call(app: app);

  @override
  ProviderAccount status(ProviderAccountStatusEnum status) =>
      call(status: status);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderAccount(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderAccount(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProviderAccount call({
    Object? app = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return ProviderAccount(
      app: app == const $CopyWithPlaceholder() || app == null
          ? _value.app
          // ignore: cast_nullable_to_non_nullable
          : app as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as ProviderAccountStatusEnum,
    );
  }
}

extension $ProviderAccountCopyWith on ProviderAccount {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProviderAccount.copyWith(...)` or `instanceOfProviderAccount.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProviderAccountCWProxy get copyWith => _$ProviderAccountCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProviderAccount _$ProviderAccountFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProviderAccount', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['app', 'status']);
      final val = ProviderAccount(
        app: $checkedConvert('app', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$ProviderAccountStatusEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ProviderAccountToJson(ProviderAccount instance) =>
    <String, dynamic>{
      'app': instance.app,
      'status': _$ProviderAccountStatusEnumEnumMap[instance.status]!,
    };

const _$ProviderAccountStatusEnumEnumMap = {
  ProviderAccountStatusEnum.connected: 'connected',
  ProviderAccountStatusEnum.pending: 'pending',
  ProviderAccountStatusEnum.error: 'error',
};

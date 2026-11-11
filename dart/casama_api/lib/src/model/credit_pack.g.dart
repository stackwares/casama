// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_pack.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreditPackCWProxy {
  CreditPack code(String code);

  CreditPack name(String name);

  CreditPack creditsUsd(num creditsUsd);

  CreditPack web(bool web);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreditPack(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreditPack(...).copyWith(id: 12, name: "My name")
  /// ```
  CreditPack call({String code, String name, num creditsUsd, bool web});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreditPack.copyWith(...)` or call `instanceOfCreditPack.copyWith.fieldName(value)` for a single field.
class _$CreditPackCWProxyImpl implements _$CreditPackCWProxy {
  const _$CreditPackCWProxyImpl(this._value);

  final CreditPack _value;

  @override
  CreditPack code(String code) => call(code: code);

  @override
  CreditPack name(String name) => call(name: name);

  @override
  CreditPack creditsUsd(num creditsUsd) => call(creditsUsd: creditsUsd);

  @override
  CreditPack web(bool web) => call(web: web);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreditPack(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreditPack(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreditPack call({
    Object? code = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? creditsUsd = const $CopyWithPlaceholder(),
    Object? web = const $CopyWithPlaceholder(),
  }) {
    return CreditPack(
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      creditsUsd:
          creditsUsd == const $CopyWithPlaceholder() || creditsUsd == null
          ? _value.creditsUsd
          // ignore: cast_nullable_to_non_nullable
          : creditsUsd as num,
      web: web == const $CopyWithPlaceholder() || web == null
          ? _value.web
          // ignore: cast_nullable_to_non_nullable
          : web as bool,
    );
  }
}

extension $CreditPackCopyWith on CreditPack {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreditPack.copyWith(...)` or `instanceOfCreditPack.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreditPackCWProxy get copyWith => _$CreditPackCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreditPack _$CreditPackFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreditPack', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['code', 'name', 'credits_usd', 'web'],
      );
      final val = CreditPack(
        code: $checkedConvert('code', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        creditsUsd: $checkedConvert('credits_usd', (v) => v as num),
        web: $checkedConvert('web', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'creditsUsd': 'credits_usd'});

Map<String, dynamic> _$CreditPackToJson(CreditPack instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'credits_usd': instance.creditsUsd,
      'web': instance.web,
    };

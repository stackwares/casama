// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redeem_invite_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RedeemInviteRequestCWProxy {
  RedeemInviteRequest email(String? email);

  RedeemInviteRequest code(String code);

  RedeemInviteRequest proof(WaitlistProof proof);

  RedeemInviteRequest idToken(String? idToken);

  RedeemInviteRequest provider(RedeemInviteRequestProviderEnum? provider);

  RedeemInviteRequest tokenNonce(String? tokenNonce);

  RedeemInviteRequest source_(String? source_);

  RedeemInviteRequest newsletter(bool? newsletter);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RedeemInviteRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RedeemInviteRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  RedeemInviteRequest call({
    String? email,
    String code,
    WaitlistProof proof,
    String? idToken,
    RedeemInviteRequestProviderEnum? provider,
    String? tokenNonce,
    String? source_,
    bool? newsletter,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRedeemInviteRequest.copyWith(...)` or call `instanceOfRedeemInviteRequest.copyWith.fieldName(value)` for a single field.
class _$RedeemInviteRequestCWProxyImpl implements _$RedeemInviteRequestCWProxy {
  const _$RedeemInviteRequestCWProxyImpl(this._value);

  final RedeemInviteRequest _value;

  @override
  RedeemInviteRequest email(String? email) => call(email: email);

  @override
  RedeemInviteRequest code(String code) => call(code: code);

  @override
  RedeemInviteRequest proof(WaitlistProof proof) => call(proof: proof);

  @override
  RedeemInviteRequest idToken(String? idToken) => call(idToken: idToken);

  @override
  RedeemInviteRequest provider(RedeemInviteRequestProviderEnum? provider) =>
      call(provider: provider);

  @override
  RedeemInviteRequest tokenNonce(String? tokenNonce) =>
      call(tokenNonce: tokenNonce);

  @override
  RedeemInviteRequest source_(String? source_) => call(source_: source_);

  @override
  RedeemInviteRequest newsletter(bool? newsletter) =>
      call(newsletter: newsletter);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RedeemInviteRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RedeemInviteRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RedeemInviteRequest call({
    Object? email = const $CopyWithPlaceholder(),
    Object? code = const $CopyWithPlaceholder(),
    Object? proof = const $CopyWithPlaceholder(),
    Object? idToken = const $CopyWithPlaceholder(),
    Object? provider = const $CopyWithPlaceholder(),
    Object? tokenNonce = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? newsletter = const $CopyWithPlaceholder(),
  }) {
    return RedeemInviteRequest(
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String?,
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      proof: proof == const $CopyWithPlaceholder() || proof == null
          ? _value.proof
          // ignore: cast_nullable_to_non_nullable
          : proof as WaitlistProof,
      idToken: idToken == const $CopyWithPlaceholder()
          ? _value.idToken
          // ignore: cast_nullable_to_non_nullable
          : idToken as String?,
      provider: provider == const $CopyWithPlaceholder()
          ? _value.provider
          // ignore: cast_nullable_to_non_nullable
          : provider as RedeemInviteRequestProviderEnum?,
      tokenNonce: tokenNonce == const $CopyWithPlaceholder()
          ? _value.tokenNonce
          // ignore: cast_nullable_to_non_nullable
          : tokenNonce as String?,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as String?,
      newsletter: newsletter == const $CopyWithPlaceholder()
          ? _value.newsletter
          // ignore: cast_nullable_to_non_nullable
          : newsletter as bool?,
    );
  }
}

extension $RedeemInviteRequestCopyWith on RedeemInviteRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRedeemInviteRequest.copyWith(...)` or `instanceOfRedeemInviteRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RedeemInviteRequestCWProxy get copyWith =>
      _$RedeemInviteRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RedeemInviteRequest _$RedeemInviteRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RedeemInviteRequest',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['code', 'proof']);
        final val = RedeemInviteRequest(
          email: $checkedConvert('email', (v) => v as String?),
          code: $checkedConvert('code', (v) => v as String),
          proof: $checkedConvert(
            'proof',
            (v) => WaitlistProof.fromJson(v as Map<String, dynamic>),
          ),
          idToken: $checkedConvert('id_token', (v) => v as String?),
          provider: $checkedConvert(
            'provider',
            (v) => $enumDecodeNullable(
              _$RedeemInviteRequestProviderEnumEnumMap,
              v,
            ),
          ),
          tokenNonce: $checkedConvert('token_nonce', (v) => v as String?),
          source_: $checkedConvert('source', (v) => v as String?),
          newsletter: $checkedConvert('newsletter', (v) => v as bool?),
        );
        return val;
      },
      fieldKeyMap: const {
        'idToken': 'id_token',
        'tokenNonce': 'token_nonce',
        'source_': 'source',
      },
    );

Map<String, dynamic> _$RedeemInviteRequestToJson(
  RedeemInviteRequest instance,
) => <String, dynamic>{
  'email': ?instance.email,
  'code': instance.code,
  'proof': instance.proof.toJson(),
  'id_token': ?instance.idToken,
  'provider': ?_$RedeemInviteRequestProviderEnumEnumMap[instance.provider],
  'token_nonce': ?instance.tokenNonce,
  'source': ?instance.source_,
  'newsletter': ?instance.newsletter,
};

const _$RedeemInviteRequestProviderEnumEnumMap = {
  RedeemInviteRequestProviderEnum.apple: 'apple',
  RedeemInviteRequestProviderEnum.google: 'google',
};

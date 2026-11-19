// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_waitlist_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$JoinWaitlistRequestCWProxy {
  JoinWaitlistRequest email(String email);

  JoinWaitlistRequest proof(WaitlistProof proof);

  JoinWaitlistRequest source_(String? source_);

  JoinWaitlistRequest ref(String? ref);

  JoinWaitlistRequest note(String? note);

  JoinWaitlistRequest selfHosting(bool? selfHosting);

  JoinWaitlistRequest newsletter(bool? newsletter);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `JoinWaitlistRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// JoinWaitlistRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  JoinWaitlistRequest call({
    String email,
    WaitlistProof proof,
    String? source_,
    String? ref,
    String? note,
    bool? selfHosting,
    bool? newsletter,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfJoinWaitlistRequest.copyWith(...)` or call `instanceOfJoinWaitlistRequest.copyWith.fieldName(value)` for a single field.
class _$JoinWaitlistRequestCWProxyImpl implements _$JoinWaitlistRequestCWProxy {
  const _$JoinWaitlistRequestCWProxyImpl(this._value);

  final JoinWaitlistRequest _value;

  @override
  JoinWaitlistRequest email(String email) => call(email: email);

  @override
  JoinWaitlistRequest proof(WaitlistProof proof) => call(proof: proof);

  @override
  JoinWaitlistRequest source_(String? source_) => call(source_: source_);

  @override
  JoinWaitlistRequest ref(String? ref) => call(ref: ref);

  @override
  JoinWaitlistRequest note(String? note) => call(note: note);

  @override
  JoinWaitlistRequest selfHosting(bool? selfHosting) =>
      call(selfHosting: selfHosting);

  @override
  JoinWaitlistRequest newsletter(bool? newsletter) =>
      call(newsletter: newsletter);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `JoinWaitlistRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// JoinWaitlistRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  JoinWaitlistRequest call({
    Object? email = const $CopyWithPlaceholder(),
    Object? proof = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? ref = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? selfHosting = const $CopyWithPlaceholder(),
    Object? newsletter = const $CopyWithPlaceholder(),
  }) {
    return JoinWaitlistRequest(
      email: email == const $CopyWithPlaceholder() || email == null
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      proof: proof == const $CopyWithPlaceholder() || proof == null
          ? _value.proof
          // ignore: cast_nullable_to_non_nullable
          : proof as WaitlistProof,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as String?,
      ref: ref == const $CopyWithPlaceholder()
          ? _value.ref
          // ignore: cast_nullable_to_non_nullable
          : ref as String?,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
      selfHosting: selfHosting == const $CopyWithPlaceholder()
          ? _value.selfHosting
          // ignore: cast_nullable_to_non_nullable
          : selfHosting as bool?,
      newsletter: newsletter == const $CopyWithPlaceholder()
          ? _value.newsletter
          // ignore: cast_nullable_to_non_nullable
          : newsletter as bool?,
    );
  }
}

extension $JoinWaitlistRequestCopyWith on JoinWaitlistRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfJoinWaitlistRequest.copyWith(...)` or `instanceOfJoinWaitlistRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$JoinWaitlistRequestCWProxy get copyWith =>
      _$JoinWaitlistRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JoinWaitlistRequest _$JoinWaitlistRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('JoinWaitlistRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['email', 'proof']);
      final val = JoinWaitlistRequest(
        email: $checkedConvert('email', (v) => v as String),
        proof: $checkedConvert(
          'proof',
          (v) => WaitlistProof.fromJson(v as Map<String, dynamic>),
        ),
        source_: $checkedConvert('source', (v) => v as String?),
        ref: $checkedConvert('ref', (v) => v as String?),
        note: $checkedConvert('note', (v) => v as String?),
        selfHosting: $checkedConvert('self_hosting', (v) => v as bool?),
        newsletter: $checkedConvert('newsletter', (v) => v as bool?),
      );
      return val;
    }, fieldKeyMap: const {'source_': 'source', 'selfHosting': 'self_hosting'});

Map<String, dynamic> _$JoinWaitlistRequestToJson(
  JoinWaitlistRequest instance,
) => <String, dynamic>{
  'email': instance.email,
  'proof': instance.proof.toJson(),
  'source': ?instance.source_,
  'ref': ?instance.ref,
  'note': ?instance.note,
  'self_hosting': ?instance.selfHosting,
  'newsletter': ?instance.newsletter,
};

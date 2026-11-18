// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_newsletter_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetNewsletterRequestCWProxy {
  SetNewsletterRequest subscribed(bool? subscribed);

  SetNewsletterRequest from(SetNewsletterRequestFromEnum? from);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetNewsletterRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetNewsletterRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetNewsletterRequest call({
    bool? subscribed,
    SetNewsletterRequestFromEnum? from,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetNewsletterRequest.copyWith(...)` or call `instanceOfSetNewsletterRequest.copyWith.fieldName(value)` for a single field.
class _$SetNewsletterRequestCWProxyImpl
    implements _$SetNewsletterRequestCWProxy {
  const _$SetNewsletterRequestCWProxyImpl(this._value);

  final SetNewsletterRequest _value;

  @override
  SetNewsletterRequest subscribed(bool? subscribed) =>
      call(subscribed: subscribed);

  @override
  SetNewsletterRequest from(SetNewsletterRequestFromEnum? from) =>
      call(from: from);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetNewsletterRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetNewsletterRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetNewsletterRequest call({
    Object? subscribed = const $CopyWithPlaceholder(),
    Object? from = const $CopyWithPlaceholder(),
  }) {
    return SetNewsletterRequest(
      subscribed: subscribed == const $CopyWithPlaceholder()
          ? _value.subscribed
          // ignore: cast_nullable_to_non_nullable
          : subscribed as bool?,
      from: from == const $CopyWithPlaceholder()
          ? _value.from
          // ignore: cast_nullable_to_non_nullable
          : from as SetNewsletterRequestFromEnum?,
    );
  }
}

extension $SetNewsletterRequestCopyWith on SetNewsletterRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetNewsletterRequest.copyWith(...)` or `instanceOfSetNewsletterRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetNewsletterRequestCWProxy get copyWith =>
      _$SetNewsletterRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetNewsletterRequest _$SetNewsletterRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SetNewsletterRequest', json, ($checkedConvert) {
  final val = SetNewsletterRequest(
    subscribed: $checkedConvert('subscribed', (v) => v as bool?),
    from: $checkedConvert(
      'from',
      (v) => $enumDecodeNullable(_$SetNewsletterRequestFromEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$SetNewsletterRequestToJson(
  SetNewsletterRequest instance,
) => <String, dynamic>{
  'subscribed': ?instance.subscribed,
  'from': ?_$SetNewsletterRequestFromEnumEnumMap[instance.from],
};

const _$SetNewsletterRequestFromEnumEnumMap = {
  SetNewsletterRequestFromEnum.settings: 'settings',
  SetNewsletterRequestFromEnum.signup: 'signup',
  SetNewsletterRequestFromEnum.card: 'card',
};

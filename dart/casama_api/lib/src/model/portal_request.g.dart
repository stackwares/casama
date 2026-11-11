// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portal_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PortalRequestCWProxy {
  PortalRequest returnUrl(String? returnUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PortalRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PortalRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  PortalRequest call({String? returnUrl});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPortalRequest.copyWith(...)` or call `instanceOfPortalRequest.copyWith.fieldName(value)` for a single field.
class _$PortalRequestCWProxyImpl implements _$PortalRequestCWProxy {
  const _$PortalRequestCWProxyImpl(this._value);

  final PortalRequest _value;

  @override
  PortalRequest returnUrl(String? returnUrl) => call(returnUrl: returnUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PortalRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PortalRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PortalRequest call({Object? returnUrl = const $CopyWithPlaceholder()}) {
    return PortalRequest(
      returnUrl: returnUrl == const $CopyWithPlaceholder()
          ? _value.returnUrl
          // ignore: cast_nullable_to_non_nullable
          : returnUrl as String?,
    );
  }
}

extension $PortalRequestCopyWith on PortalRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPortalRequest.copyWith(...)` or `instanceOfPortalRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PortalRequestCWProxy get copyWith => _$PortalRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PortalRequest _$PortalRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PortalRequest', json, ($checkedConvert) {
      final val = PortalRequest(
        returnUrl: $checkedConvert('return_url', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'returnUrl': 'return_url'});

Map<String, dynamic> _$PortalRequestToJson(PortalRequest instance) =>
    <String, dynamic>{'return_url': ?instance.returnUrl};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_consent_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$McpConsentResultCWProxy {
  McpConsentResult redirectUrl(String redirectUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpConsentResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpConsentResult(...).copyWith(id: 12, name: "My name")
  /// ```
  McpConsentResult call({String redirectUrl});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMcpConsentResult.copyWith(...)` or call `instanceOfMcpConsentResult.copyWith.fieldName(value)` for a single field.
class _$McpConsentResultCWProxyImpl implements _$McpConsentResultCWProxy {
  const _$McpConsentResultCWProxyImpl(this._value);

  final McpConsentResult _value;

  @override
  McpConsentResult redirectUrl(String redirectUrl) =>
      call(redirectUrl: redirectUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpConsentResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpConsentResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  McpConsentResult call({Object? redirectUrl = const $CopyWithPlaceholder()}) {
    return McpConsentResult(
      redirectUrl:
          redirectUrl == const $CopyWithPlaceholder() || redirectUrl == null
          ? _value.redirectUrl
          // ignore: cast_nullable_to_non_nullable
          : redirectUrl as String,
    );
  }
}

extension $McpConsentResultCopyWith on McpConsentResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMcpConsentResult.copyWith(...)` or `instanceOfMcpConsentResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$McpConsentResultCWProxy get copyWith => _$McpConsentResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

McpConsentResult _$McpConsentResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('McpConsentResult', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['redirect_url']);
      final val = McpConsentResult(
        redirectUrl: $checkedConvert('redirect_url', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'redirectUrl': 'redirect_url'});

Map<String, dynamic> _$McpConsentResultToJson(McpConsentResult instance) =>
    <String, dynamic>{'redirect_url': instance.redirectUrl};

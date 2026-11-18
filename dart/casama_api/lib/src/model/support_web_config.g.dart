// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_web_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SupportWebConfigCWProxy {
  SupportWebConfig assistant(bool assistant);

  SupportWebConfig turnstileSiteKey(String? turnstileSiteKey);

  SupportWebConfig email(String email);

  SupportWebConfig docsUrl(String docsUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportWebConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportWebConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  SupportWebConfig call({
    bool assistant,
    String? turnstileSiteKey,
    String email,
    String docsUrl,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSupportWebConfig.copyWith(...)` or call `instanceOfSupportWebConfig.copyWith.fieldName(value)` for a single field.
class _$SupportWebConfigCWProxyImpl implements _$SupportWebConfigCWProxy {
  const _$SupportWebConfigCWProxyImpl(this._value);

  final SupportWebConfig _value;

  @override
  SupportWebConfig assistant(bool assistant) => call(assistant: assistant);

  @override
  SupportWebConfig turnstileSiteKey(String? turnstileSiteKey) =>
      call(turnstileSiteKey: turnstileSiteKey);

  @override
  SupportWebConfig email(String email) => call(email: email);

  @override
  SupportWebConfig docsUrl(String docsUrl) => call(docsUrl: docsUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportWebConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportWebConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SupportWebConfig call({
    Object? assistant = const $CopyWithPlaceholder(),
    Object? turnstileSiteKey = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? docsUrl = const $CopyWithPlaceholder(),
  }) {
    return SupportWebConfig(
      assistant: assistant == const $CopyWithPlaceholder() || assistant == null
          ? _value.assistant
          // ignore: cast_nullable_to_non_nullable
          : assistant as bool,
      turnstileSiteKey: turnstileSiteKey == const $CopyWithPlaceholder()
          ? _value.turnstileSiteKey
          // ignore: cast_nullable_to_non_nullable
          : turnstileSiteKey as String?,
      email: email == const $CopyWithPlaceholder() || email == null
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      docsUrl: docsUrl == const $CopyWithPlaceholder() || docsUrl == null
          ? _value.docsUrl
          // ignore: cast_nullable_to_non_nullable
          : docsUrl as String,
    );
  }
}

extension $SupportWebConfigCopyWith on SupportWebConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSupportWebConfig.copyWith(...)` or `instanceOfSupportWebConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SupportWebConfigCWProxy get copyWith => _$SupportWebConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportWebConfig _$SupportWebConfigFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SupportWebConfig',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'assistant',
            'turnstile_site_key',
            'email',
            'docs_url',
          ],
        );
        final val = SupportWebConfig(
          assistant: $checkedConvert('assistant', (v) => v as bool),
          turnstileSiteKey: $checkedConvert(
            'turnstile_site_key',
            (v) => v as String?,
          ),
          email: $checkedConvert('email', (v) => v as String),
          docsUrl: $checkedConvert('docs_url', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'turnstileSiteKey': 'turnstile_site_key',
        'docsUrl': 'docs_url',
      },
    );

Map<String, dynamic> _$SupportWebConfigToJson(SupportWebConfig instance) =>
    <String, dynamic>{
      'assistant': instance.assistant,
      'turnstile_site_key': instance.turnstileSiteKey,
      'email': instance.email,
      'docs_url': instance.docsUrl,
    };

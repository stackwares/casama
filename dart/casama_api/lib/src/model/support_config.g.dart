// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SupportConfigCWProxy {
  SupportConfig assistant(bool assistant);

  SupportConfig tickets(bool tickets);

  SupportConfig email(String email);

  SupportConfig docsUrl(String docsUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  SupportConfig call({
    bool assistant,
    bool tickets,
    String email,
    String docsUrl,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSupportConfig.copyWith(...)` or call `instanceOfSupportConfig.copyWith.fieldName(value)` for a single field.
class _$SupportConfigCWProxyImpl implements _$SupportConfigCWProxy {
  const _$SupportConfigCWProxyImpl(this._value);

  final SupportConfig _value;

  @override
  SupportConfig assistant(bool assistant) => call(assistant: assistant);

  @override
  SupportConfig tickets(bool tickets) => call(tickets: tickets);

  @override
  SupportConfig email(String email) => call(email: email);

  @override
  SupportConfig docsUrl(String docsUrl) => call(docsUrl: docsUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SupportConfig call({
    Object? assistant = const $CopyWithPlaceholder(),
    Object? tickets = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? docsUrl = const $CopyWithPlaceholder(),
  }) {
    return SupportConfig(
      assistant: assistant == const $CopyWithPlaceholder() || assistant == null
          ? _value.assistant
          // ignore: cast_nullable_to_non_nullable
          : assistant as bool,
      tickets: tickets == const $CopyWithPlaceholder() || tickets == null
          ? _value.tickets
          // ignore: cast_nullable_to_non_nullable
          : tickets as bool,
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

extension $SupportConfigCopyWith on SupportConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSupportConfig.copyWith(...)` or `instanceOfSupportConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SupportConfigCWProxy get copyWith => _$SupportConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportConfig _$SupportConfigFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SupportConfig', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['assistant', 'tickets', 'email', 'docs_url'],
      );
      final val = SupportConfig(
        assistant: $checkedConvert('assistant', (v) => v as bool),
        tickets: $checkedConvert('tickets', (v) => v as bool),
        email: $checkedConvert('email', (v) => v as String),
        docsUrl: $checkedConvert('docs_url', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'docsUrl': 'docs_url'});

Map<String, dynamic> _$SupportConfigToJson(SupportConfig instance) =>
    <String, dynamic>{
      'assistant': instance.assistant,
      'tickets': instance.tickets,
      'email': instance.email,
      'docs_url': instance.docsUrl,
    };

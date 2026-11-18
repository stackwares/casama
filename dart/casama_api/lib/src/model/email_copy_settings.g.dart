// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_copy_settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EmailCopySettingsCWProxy {
  EmailCopySettings copy(Map<String, Object?> copy);

  EmailCopySettings defaults(Map<String, Object?> defaults);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EmailCopySettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EmailCopySettings(...).copyWith(id: 12, name: "My name")
  /// ```
  EmailCopySettings call({
    Map<String, Object?> copy,
    Map<String, Object?> defaults,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfEmailCopySettings.copyWith(...)` or call `instanceOfEmailCopySettings.copyWith.fieldName(value)` for a single field.
class _$EmailCopySettingsCWProxyImpl implements _$EmailCopySettingsCWProxy {
  const _$EmailCopySettingsCWProxyImpl(this._value);

  final EmailCopySettings _value;

  @override
  EmailCopySettings copy(Map<String, Object?> copy) => call(copy: copy);

  @override
  EmailCopySettings defaults(Map<String, Object?> defaults) =>
      call(defaults: defaults);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EmailCopySettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EmailCopySettings(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  EmailCopySettings call({
    Object? copy = const $CopyWithPlaceholder(),
    Object? defaults = const $CopyWithPlaceholder(),
  }) {
    return EmailCopySettings(
      copy: copy == const $CopyWithPlaceholder() || copy == null
          ? _value.copy
          // ignore: cast_nullable_to_non_nullable
          : copy as Map<String, Object?>,
      defaults: defaults == const $CopyWithPlaceholder() || defaults == null
          ? _value.defaults
          // ignore: cast_nullable_to_non_nullable
          : defaults as Map<String, Object?>,
    );
  }
}

extension $EmailCopySettingsCopyWith on EmailCopySettings {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfEmailCopySettings.copyWith(...)` or `instanceOfEmailCopySettings.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EmailCopySettingsCWProxy get copyWith =>
      _$EmailCopySettingsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailCopySettings _$EmailCopySettingsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EmailCopySettings', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['copy', 'defaults']);
      final val = EmailCopySettings(
        copy: $checkedConvert('copy', (v) => v as Map<String, dynamic>),
        defaults: $checkedConvert('defaults', (v) => v as Map<String, dynamic>),
      );
      return val;
    });

Map<String, dynamic> _$EmailCopySettingsToJson(EmailCopySettings instance) =>
    <String, dynamic>{'copy': instance.copy, 'defaults': instance.defaults};

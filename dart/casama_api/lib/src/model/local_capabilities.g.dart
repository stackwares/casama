// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_capabilities.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LocalCapabilitiesCWProxy {
  LocalCapabilities shell(bool? shell);

  LocalCapabilities files(bool? files);

  LocalCapabilities browser(bool? browser);

  LocalCapabilities desktop(bool? desktop);

  LocalCapabilities mcp(bool? mcp);

  LocalCapabilities messages(bool? messages);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LocalCapabilities(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LocalCapabilities(...).copyWith(id: 12, name: "My name")
  /// ```
  LocalCapabilities call({
    bool? shell,
    bool? files,
    bool? browser,
    bool? desktop,
    bool? mcp,
    bool? messages,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLocalCapabilities.copyWith(...)` or call `instanceOfLocalCapabilities.copyWith.fieldName(value)` for a single field.
class _$LocalCapabilitiesCWProxyImpl implements _$LocalCapabilitiesCWProxy {
  const _$LocalCapabilitiesCWProxyImpl(this._value);

  final LocalCapabilities _value;

  @override
  LocalCapabilities shell(bool? shell) => call(shell: shell);

  @override
  LocalCapabilities files(bool? files) => call(files: files);

  @override
  LocalCapabilities browser(bool? browser) => call(browser: browser);

  @override
  LocalCapabilities desktop(bool? desktop) => call(desktop: desktop);

  @override
  LocalCapabilities mcp(bool? mcp) => call(mcp: mcp);

  @override
  LocalCapabilities messages(bool? messages) => call(messages: messages);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LocalCapabilities(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LocalCapabilities(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LocalCapabilities call({
    Object? shell = const $CopyWithPlaceholder(),
    Object? files = const $CopyWithPlaceholder(),
    Object? browser = const $CopyWithPlaceholder(),
    Object? desktop = const $CopyWithPlaceholder(),
    Object? mcp = const $CopyWithPlaceholder(),
    Object? messages = const $CopyWithPlaceholder(),
  }) {
    return LocalCapabilities(
      shell: shell == const $CopyWithPlaceholder()
          ? _value.shell
          // ignore: cast_nullable_to_non_nullable
          : shell as bool?,
      files: files == const $CopyWithPlaceholder()
          ? _value.files
          // ignore: cast_nullable_to_non_nullable
          : files as bool?,
      browser: browser == const $CopyWithPlaceholder()
          ? _value.browser
          // ignore: cast_nullable_to_non_nullable
          : browser as bool?,
      desktop: desktop == const $CopyWithPlaceholder()
          ? _value.desktop
          // ignore: cast_nullable_to_non_nullable
          : desktop as bool?,
      mcp: mcp == const $CopyWithPlaceholder()
          ? _value.mcp
          // ignore: cast_nullable_to_non_nullable
          : mcp as bool?,
      messages: messages == const $CopyWithPlaceholder()
          ? _value.messages
          // ignore: cast_nullable_to_non_nullable
          : messages as bool?,
    );
  }
}

extension $LocalCapabilitiesCopyWith on LocalCapabilities {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLocalCapabilities.copyWith(...)` or `instanceOfLocalCapabilities.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LocalCapabilitiesCWProxy get copyWith =>
      _$LocalCapabilitiesCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalCapabilities _$LocalCapabilitiesFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LocalCapabilities', json, ($checkedConvert) {
      final val = LocalCapabilities(
        shell: $checkedConvert('shell', (v) => v as bool?),
        files: $checkedConvert('files', (v) => v as bool?),
        browser: $checkedConvert('browser', (v) => v as bool?),
        desktop: $checkedConvert('desktop', (v) => v as bool?),
        mcp: $checkedConvert('mcp', (v) => v as bool?),
        messages: $checkedConvert('messages', (v) => v as bool?),
      );
      return val;
    });

Map<String, dynamic> _$LocalCapabilitiesToJson(LocalCapabilities instance) =>
    <String, dynamic>{
      'shell': ?instance.shell,
      'files': ?instance.files,
      'browser': ?instance.browser,
      'desktop': ?instance.desktop,
      'mcp': ?instance.mcp,
      'messages': ?instance.messages,
    };

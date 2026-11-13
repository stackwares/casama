// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slack_install_link.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SlackInstallLinkCWProxy {
  SlackInstallLink url(String url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SlackInstallLink(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SlackInstallLink(...).copyWith(id: 12, name: "My name")
  /// ```
  SlackInstallLink call({String url});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSlackInstallLink.copyWith(...)` or call `instanceOfSlackInstallLink.copyWith.fieldName(value)` for a single field.
class _$SlackInstallLinkCWProxyImpl implements _$SlackInstallLinkCWProxy {
  const _$SlackInstallLinkCWProxyImpl(this._value);

  final SlackInstallLink _value;

  @override
  SlackInstallLink url(String url) => call(url: url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SlackInstallLink(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SlackInstallLink(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SlackInstallLink call({Object? url = const $CopyWithPlaceholder()}) {
    return SlackInstallLink(
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
    );
  }
}

extension $SlackInstallLinkCopyWith on SlackInstallLink {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSlackInstallLink.copyWith(...)` or `instanceOfSlackInstallLink.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SlackInstallLinkCWProxy get copyWith => _$SlackInstallLinkCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SlackInstallLink _$SlackInstallLinkFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SlackInstallLink', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['url']);
      final val = SlackInstallLink(
        url: $checkedConvert('url', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SlackInstallLinkToJson(SlackInstallLink instance) =>
    <String, dynamic>{'url': instance.url};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'widget_push_token.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WidgetPushTokenCWProxy {
  WidgetPushToken token(String token);

  WidgetPushToken kind(WidgetPushTokenKindEnum kind);

  WidgetPushToken sandbox(bool? sandbox);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WidgetPushToken(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WidgetPushToken(...).copyWith(id: 12, name: "My name")
  /// ```
  WidgetPushToken call({
    String token,
    WidgetPushTokenKindEnum kind,
    bool? sandbox,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWidgetPushToken.copyWith(...)` or call `instanceOfWidgetPushToken.copyWith.fieldName(value)` for a single field.
class _$WidgetPushTokenCWProxyImpl implements _$WidgetPushTokenCWProxy {
  const _$WidgetPushTokenCWProxyImpl(this._value);

  final WidgetPushToken _value;

  @override
  WidgetPushToken token(String token) => call(token: token);

  @override
  WidgetPushToken kind(WidgetPushTokenKindEnum kind) => call(kind: kind);

  @override
  WidgetPushToken sandbox(bool? sandbox) => call(sandbox: sandbox);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WidgetPushToken(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WidgetPushToken(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WidgetPushToken call({
    Object? token = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? sandbox = const $CopyWithPlaceholder(),
  }) {
    return WidgetPushToken(
      token: token == const $CopyWithPlaceholder() || token == null
          ? _value.token
          // ignore: cast_nullable_to_non_nullable
          : token as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as WidgetPushTokenKindEnum,
      sandbox: sandbox == const $CopyWithPlaceholder()
          ? _value.sandbox
          // ignore: cast_nullable_to_non_nullable
          : sandbox as bool?,
    );
  }
}

extension $WidgetPushTokenCopyWith on WidgetPushToken {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWidgetPushToken.copyWith(...)` or `instanceOfWidgetPushToken.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WidgetPushTokenCWProxy get copyWith => _$WidgetPushTokenCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WidgetPushToken _$WidgetPushTokenFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WidgetPushToken', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['token', 'kind']);
      final val = WidgetPushToken(
        token: $checkedConvert('token', (v) => v as String),
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$WidgetPushTokenKindEnumEnumMap, v),
        ),
        sandbox: $checkedConvert('sandbox', (v) => v as bool?),
      );
      return val;
    });

Map<String, dynamic> _$WidgetPushTokenToJson(WidgetPushToken instance) =>
    <String, dynamic>{
      'token': instance.token,
      'kind': _$WidgetPushTokenKindEnumEnumMap[instance.kind]!,
      'sandbox': ?instance.sandbox,
    };

const _$WidgetPushTokenKindEnumEnumMap = {
  WidgetPushTokenKindEnum.apnsWidgets: 'apns_widgets',
  WidgetPushTokenKindEnum.fcm: 'fcm',
};

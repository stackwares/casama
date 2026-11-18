// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_web_session.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SupportWebSessionCWProxy {
  SupportWebSession session(String session);

  SupportWebSession expiresAt(DateTime expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportWebSession(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportWebSession(...).copyWith(id: 12, name: "My name")
  /// ```
  SupportWebSession call({String session, DateTime expiresAt});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSupportWebSession.copyWith(...)` or call `instanceOfSupportWebSession.copyWith.fieldName(value)` for a single field.
class _$SupportWebSessionCWProxyImpl implements _$SupportWebSessionCWProxy {
  const _$SupportWebSessionCWProxyImpl(this._value);

  final SupportWebSession _value;

  @override
  SupportWebSession session(String session) => call(session: session);

  @override
  SupportWebSession expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportWebSession(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportWebSession(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SupportWebSession call({
    Object? session = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
  }) {
    return SupportWebSession(
      session: session == const $CopyWithPlaceholder() || session == null
          ? _value.session
          // ignore: cast_nullable_to_non_nullable
          : session as String,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
    );
  }
}

extension $SupportWebSessionCopyWith on SupportWebSession {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSupportWebSession.copyWith(...)` or `instanceOfSupportWebSession.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SupportWebSessionCWProxy get copyWith =>
      _$SupportWebSessionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportWebSession _$SupportWebSessionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SupportWebSession', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['session', 'expires_at']);
      final val = SupportWebSession(
        session: $checkedConvert('session', (v) => v as String),
        expiresAt: $checkedConvert(
          'expires_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'expiresAt': 'expires_at'});

Map<String, dynamic> _$SupportWebSessionToJson(SupportWebSession instance) =>
    <String, dynamic>{
      'session': instance.session,
      'expires_at': instance.expiresAt.toIso8601String(),
    };

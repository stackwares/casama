// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'start_welcome_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StartWelcomeRequestCWProxy {
  StartWelcomeRequest firstName(String? firstName);

  StartWelcomeRequest botName(String? botName);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `StartWelcomeRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StartWelcomeRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  StartWelcomeRequest call({String? firstName, String? botName});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfStartWelcomeRequest.copyWith(...)` or call `instanceOfStartWelcomeRequest.copyWith.fieldName(value)` for a single field.
class _$StartWelcomeRequestCWProxyImpl implements _$StartWelcomeRequestCWProxy {
  const _$StartWelcomeRequestCWProxyImpl(this._value);

  final StartWelcomeRequest _value;

  @override
  StartWelcomeRequest firstName(String? firstName) =>
      call(firstName: firstName);

  @override
  StartWelcomeRequest botName(String? botName) => call(botName: botName);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `StartWelcomeRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StartWelcomeRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  StartWelcomeRequest call({
    Object? firstName = const $CopyWithPlaceholder(),
    Object? botName = const $CopyWithPlaceholder(),
  }) {
    return StartWelcomeRequest(
      firstName: firstName == const $CopyWithPlaceholder()
          ? _value.firstName
          // ignore: cast_nullable_to_non_nullable
          : firstName as String?,
      botName: botName == const $CopyWithPlaceholder()
          ? _value.botName
          // ignore: cast_nullable_to_non_nullable
          : botName as String?,
    );
  }
}

extension $StartWelcomeRequestCopyWith on StartWelcomeRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfStartWelcomeRequest.copyWith(...)` or `instanceOfStartWelcomeRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StartWelcomeRequestCWProxy get copyWith =>
      _$StartWelcomeRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StartWelcomeRequest _$StartWelcomeRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StartWelcomeRequest', json, ($checkedConvert) {
      final val = StartWelcomeRequest(
        firstName: $checkedConvert('first_name', (v) => v as String?),
        botName: $checkedConvert('bot_name', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'firstName': 'first_name', 'botName': 'bot_name'});

Map<String, dynamic> _$StartWelcomeRequestToJson(
  StartWelcomeRequest instance,
) => <String, dynamic>{
  'first_name': ?instance.firstName,
  'bot_name': ?instance.botName,
};
